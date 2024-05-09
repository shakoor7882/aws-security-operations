data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account = data.aws_caller_identity.current.account_id
  region  = data.aws_region.current.name
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.default.arn
  log_destination = aws_cloudwatch_log_group.default.arn
  traffic_type    = "ALL"
  vpc_id          = var.vpc_id

  tags = {
    Name = "${var.workload}-flowlog"
  }

  depends_on = [aws_iam_role_policy.cloudwatch]
}

resource "aws_cloudwatch_log_group" "default" {
  name              = "${var.workload}-flowlog"
  retention_in_days = 7
}

// CloudWatch Logs
resource "aws_iam_role" "default" {
  name = "${var.workload}-vpc-flowlogs-role"

  # Based on this: https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-cwl.html
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "vpc-flow-logs.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            "aws:SourceAccount" : "${local.account}"
          },
          "ArnLike" : {
            "aws:SourceArn" : "arn:aws:ec2:${local.region}:${local.account}:vpc-flow-log/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "${var.workload}-vpc-flowlogs-policy"
  role = aws_iam_role.default.id

  # Based on this: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/iam-access-control-overview-cwl.html
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        "Resource" : [
          "arn:aws:logs:${local.region}:${local.account}:log-group:*",
          "arn:aws:logs:${local.region}:${local.account}:log-group:*:*",
          "arn:aws:logs:${local.region}:${local.account}:log-group:*:log-stream:*",
          "arn:aws:logs:${local.region}:${local.account}:destination:*",
        ],
      }
    ]
  })
}

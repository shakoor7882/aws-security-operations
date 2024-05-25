data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  aws_region     = data.aws_region.current.name
  aws_account_id = data.aws_caller_identity.current.account_id
}

resource "aws_cloudwatch_log_group" "default" {
  name              = "aws-waf-logs-${var.workload}"
  retention_in_days = 7
  skip_destroy      = false
}

resource "aws_wafv2_web_acl_logging_configuration" "default" {
  log_destination_configs = [aws_cloudwatch_log_group.default.arn]
  resource_arn            = var.web_acl_arn
}

resource "aws_cloudwatch_log_resource_policy" "default" {
  policy_document = data.aws_iam_policy_document.default.json
  policy_name     = "${var.workload}-waf-webacl"
}

data "aws_iam_policy_document" "default" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.default.arn}:*"]
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:logs:${local.aws_region}:${local.aws_account_id}:*"]
      variable = "aws:SourceArn"
    }
    condition {
      test     = "StringEquals"
      values   = [tostring(local.aws_account_id)]
      variable = "aws:SourceAccount"
    }
  }
}

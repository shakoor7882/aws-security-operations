resource "aws_sns_topic" "guardduty" {
  name = "guardduty-findings"
}

resource "aws_sns_topic_subscription" "guardduty" {
  topic_arn = aws_sns_topic.guardduty.arn
  protocol  = "email"
  endpoint  = var.email
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.guardduty.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.guardduty.arn]
  }
}

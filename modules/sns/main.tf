resource "aws_sns_topic" "guardduty" {
  name       = "guardduty-findings"
  fifo_topic = false
}

resource "aws_sns_topic_subscription" "guardduty" {
  topic_arn = aws_sns_topic.guardduty.arn
  protocol  = "email"
  endpoint  = var.email
}

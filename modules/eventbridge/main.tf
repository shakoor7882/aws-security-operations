resource "aws_cloudwatch_event_rule" "guardduty" {
  name        = "capture-guardduty-findings"
  description = "Capture each GuardDuty finding."

  event_pattern = jsonencode({
    "source" : ["aws.guardduty"],
    "detail-type" : ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.guardduty.name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn
}

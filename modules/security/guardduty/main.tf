resource "aws_guardduty_detector" "main" {
  enable = var.enable_guardduty
}

resource "aws_guardduty_detector_feature" "runtime_monitoring" {
  detector_id = aws_guardduty_detector.main.id
  name        = "RUNTIME_MONITORING"
  status      = var.enable_runtime_monitoring ? "ENABLED" : "DISABLED"

  additional_configuration {
    name   = "EKS_ADDON_MANAGEMENT"
    status = "DISABLED"
  }

  additional_configuration {
    name   = "ECS_FARGATE_AGENT_MANAGEMENT"
    status = "ENABLED"
  }

  additional_configuration {
    name   = "EC2_AGENT_MANAGEMENT"
    status = "ENABLED"
  }
}

### Threat IP set ###
resource "random_string" "bucket" {
  length    = 10
  min_lower = 10
  special   = false
}

locals {
  threat      = "threat.txt"
  threat_path = "${path.module}/${local.threat}"
}

resource "aws_s3_bucket" "ipset" {
  bucket        = "bucket-guardduty-security-${random_string.bucket.result}"
  force_destroy = true
}

resource "aws_s3_object" "threat" {
  bucket = aws_s3_bucket.ipset.id
  key    = local.threat
  source = local.threat_path
  etag   = filemd5(local.threat_path)
}

resource "aws_guardduty_threatintelset" "threat" {
  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "https://${aws_s3_bucket.ipset.bucket_domain_name}/${aws_s3_object.threat.key}"
  name        = "threat-ipset-001"
}

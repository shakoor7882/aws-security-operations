locals {
  metrics_enabled         = true
  sample_requests_enabled = true
}

module "waf_logging" {
  source      = "./logging"
  workload    = var.workload
  web_acl_arn = aws_wafv2_web_acl.default.arn
}

resource "aws_wafv2_web_acl" "default" {
  name        = "waf-${var.workload}"
  description = "ECS Fargate ELB WAF"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = local.metrics_enabled
    metric_name                = "waf-aclmetric-${var.workload}"
    sampled_requests_enabled   = local.sample_requests_enabled
  }

  #################################
  ### Custom Rules
  #################################

  ###  Allow Brazil only ###

  rule {
    name     = "${var.workload}-allowed-contries"
    priority = 0

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = var.allowed_country_codes
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = local.metrics_enabled
      metric_name                = "${var.workload}-allowed-contries"
      sampled_requests_enabled   = local.sample_requests_enabled
    }
  }

  ### Rate Limit ###

  rule {
    name     = "${var.workload}-rate-limit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        aggregate_key_type    = "IP"
        evaluation_window_sec = 60
        limit                 = var.rate_limit
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = local.metrics_enabled
      metric_name                = "${var.workload}-rate-limit"
      sampled_requests_enabled   = local.sample_requests_enabled
    }
  }


  #################################
  ### Managed Rules
  #################################

  ### Reputation List ###

  rule {
    name     = "aws-ip-reputation"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = local.metrics_enabled
      metric_name                = "aws-ip-reputation-metric"
      sampled_requests_enabled   = local.sample_requests_enabled
    }
  }

  ### Anonymous IP List ###

  rule {
    name     = "aws-anonymous-ip"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = local.metrics_enabled
      metric_name                = "aws-anonymous-ip-metric"
      sampled_requests_enabled   = local.sample_requests_enabled
    }
  }


  ### Core/Common ###

  # https://repost.aws/knowledge-center/waf-http-request-body-inspection
  rule {
    name     = "aws-common"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "SizeRestrictions_BODY"

          action_to_use {
            count {
            }
          }
        }

        rule_action_override {
          name = "CrossSiteScripting_BODY"

          action_to_use {
            count {
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = local.metrics_enabled
      metric_name                = "aws-common-metric"
      sampled_requests_enabled   = local.sample_requests_enabled
    }
  }

  ### Known Bad Inputs ###

  rule {
    name     = "aws-knownbadinputs"
    priority = 7

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = local.metrics_enabled
      metric_name                = "aws-knownbadinputs-metric"
      sampled_requests_enabled   = local.sample_requests_enabled
    }
  }


  ### SQLi ###

  rule {
    name     = "aws-sqli"
    priority = 8

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = local.metrics_enabled
      metric_name                = "aws-sqli-metric"
      sampled_requests_enabled   = local.sample_requests_enabled
    }
  }

  ### Linux ###

  # rule {
  #   name     = "aws-linux"
  #   priority = 60

  #   override_action {
  #     none {}
  #   }

  #   statement {
  #     managed_rule_group_statement {
  #       name        = "AWSManagedRulesLinuxRuleSet"
  #       vendor_name = "AWS"
  #     }
  #   }

  #   visibility_config {
  #     cloudwatch_metrics_enabled = local.metrics_enabled
  #     metric_name                = "aws-linux-metric"
  #     sampled_requests_enabled   = local.sample_requests_enabled
  #   }
  # }

  ### UNIX ###

  # rule {
  #   name     = "aws-unix"
  #   priority = 70

  #   override_action {
  #     none {}
  #   }

  #   statement {
  #     managed_rule_group_statement {
  #       name        = "AWSManagedRulesUnixRuleSet"
  #       vendor_name = "AWS"
  #     }
  #   }

  #   visibility_config {
  #     cloudwatch_metrics_enabled = local.metrics_enabled
  #     metric_name                = "aws-unix-metric"
  #     sampled_requests_enabled   = local.sample_requests_enabled
  #   }
  # }
}

resource "aws_wafv2_web_acl_association" "default" {
  resource_arn = var.resource_arn
  web_acl_arn  = aws_wafv2_web_acl.default.arn
}

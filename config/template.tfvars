# General
aws_region = "us-east-2"

# GuardDuty
enable_guardduty                    = true
enable_guardduty_runtime_monitoring = true

# EC2
enable_ec2    = false
workload_type = "ASG" # ASG, INSTANCE
ami           = "ami-09b90e09742640522"
instance_type = "t3.micro"

# Fargate
enable_fargate         = false
enable_fargate_service = false
ecs_task_cpu           = 512
ecs_task_memory        = 1024

# WAF
enable_waf                     = false
waf_allowed_country_codes      = ["BR"]
waf_rate_limit                 = 100
waf_rate_evaluation_window_sec = 60

# SNS
sns_email = ""

# Route 53 DNS Firewall
route53_dns_firewall_blocked_domains = ["google.com."]

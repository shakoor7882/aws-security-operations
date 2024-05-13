# General
aws_region = "us-east-2"

# GuardDuty
enable_guardduty                    = true
enable_guardduty_runtime_monitoring = true

# EC2
workload_type = "ASG" # ASG, INSTANCE
ami           = "ami-09b90e09742640522"
instance_type = "t3.micro"
user_data     = "al2023.sh"

# SNS
sns_email = ""

# Route 53 DNS Firewall
route53_dns_firewall_blocked_domains = ["google.com."]

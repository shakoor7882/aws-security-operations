#!/usr/bin/env bash

dnf check-update

# Install packages
yum install amazon-cloudwatch-agent nmap -y

# CloudWatch Agent
ssmParameterName=AmazonCloudWatch-linux-terraform
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:$ssmParameterName

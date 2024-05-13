#!/usr/bin/env bash

dnf check-update

# CloudWatch Agent
yum install amazon-cloudwatch-agent -y
ssmParameterName=AmazonCloudWatch-linux-terraform
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:$ssmParameterName

#!/usr/bin/env bash

dnf check-update

# CloudWatch Agent
ssmParameterName=AmazonCloudWatch-linux-terraform
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:$ssmParameterName

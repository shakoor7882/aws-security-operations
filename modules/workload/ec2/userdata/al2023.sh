#!/usr/bin/env bash

dnf check-update

# CloudWatch Agent
# wget https://amazoncloudwatch-agent-us-east-2.s3.us-east-2.amazonaws.com/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb
# dpkg -i -E ./amazon-cloudwatch-agent.deb

ssmParameterName=AmazonCloudWatch-linux-terraform
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:$ssmParameterName

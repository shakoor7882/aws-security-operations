# aws-security-operations

add email

confirm

isolate the instance

cloud-init status
systemctl status amazon-cloudwatch-agent

```sh
aws ssm start-session --target i-00000000000000000
```

Always good to check for updates:

```sh
sudo su -

dnf check-update
dnf update
dnf upgrade
```


```sh
dig guarddutyc2activityb.com
dig GuardDutyC2ActivityB.com any
```

GuardDuty-initiated malware scan is enabled

TODO: Add detective
TODO: Add Security Lake

https://www.youtube.com/watch?v=fpShCxD8kFA

https://github.com/awslabs/amazon-guardduty-tester

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-connection-tracking.html
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-connection-tracking.html


Closing untracked connections:

https://dev.to/aws-builders/aws-incident-response-how-to-contain-an-ec2-instance-pjk



Getting the private key from Parameter Store:

```sh
aws ssm get-parameter \
    --name "wms-private-key-openssh" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text > rsa_private_key
```

Connect to SSH:

```sh
ssh -i ./rsa_private_key ec2-user@infected.intranet.wms.com
```

## Scenarios

###

1. Quarantine the instance using the [AWS-QuarantineEC2Instance][1] runbook.

```sh

```





https://github.com/epomatti/aws-cloudwatch-subscriptions






[1]: https://console.aws.amazon.com/systems-manager/automation/execute/AWS-QuarantineEC2Instance

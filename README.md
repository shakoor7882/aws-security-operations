# AWS Security Operations

Simulation of detection, containment, and remediation techniques in AWS as part of a SOC approach.

Roadmap:

- [x] Application infrastructure
- [x] Security infrastructure
- [x] GuardDuty Runtime Monitoring
- [x] Route 53 DNS Firewall
- [ ] ASG
- [ ] Inspector
- [ ] Security Lake
- [ ] Detective

<img src=".assets/aws-secops.png" />

## Setup

Set up the `.auto.tfvars` file:

```sh
cp config/template.tfvars .auto.tfvars
```

At a minimum, set the `sns_email` variable to your test email. This will be used for a GuardDuty subscription and will require an approval after creation.

Create the infrastructure:

```sh
terraform init
terraform apply -auto-approve
```

Check your email and approve the SNS subscription.

Connect to the instances and confirm that the setup was complete successfully:

```sh
# Connect using Session Manager
aws ssm start-session --target i-00000000000000000

# Elevate to super user
sudo su -

# Check the init script
cloud-init status
systemctl status amazon-cloudwatch-agent

# Update and upgrade if required
dnf check-update
dnf update
dnf upgrade
```

## Scenario 1: GuardDuty Runtime Monitoring

### Detection

Connect to the application instance and test a [GuardDuty Runtime Monitoring][3] finding. Example:

```sh
dig guarddutyc2activityb.com
```

This will force a [Backdoor:Runtime/C&CActivity.B!DNS][2] finding to be triggered.

In this simple example, the event will be captured in EventBridge and sent to an SNS topic. In a production use case, additional integration options may be implemented, not only notification, but also with a SOAR.

### Containment

Upon detecting the threat, a security operations team may choose to quarantine the instance to protected the data.

In this exemple, run the [AWS-QuarantineEC2Instance][1] runbook. The security group `isolated-security-group` has been pre-created by Terraform to be in scope of the `destroy` stage.

If the instance would be running any processes in production, this would disable that process.

A robust containment plan would include a remediation action that does minimal impact to production. One option in this case would be having a pre-baked AMI which could then be used to create a new server (assuming the AMI is not infected). This would likely require an integrated DevSecOps approach with the application and infrastructure teams, which is complex in planning and execution. When implementing Infrastructure as Code, the design should also consider such scenarios.

The instance should be kept running in quarantine as to provide a better inspection scenario.

### Inspection

An engineer would now be able to inspect the infected instance.

Log in to the security jump server, which is in a peered VPC.

Get the application instance private key from Parameter Store:

```sh
aws ssm get-parameter \
    --name "wms-private-key-openssh" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text > rsa_private_key
```

Set the appropriate private key file permissions:

```sh
chmod 600 ~/.ssh/id_rsa
```

Connect to the infected instance via SSH:

```sh
ssh -i ./rsa_private_key ec2-user@infected.intranet.wms.com
```

---

### Clean-up

Delete any snapshots created by quarantine automation.

Destroy the Terraform resources:

```sh
terraform destroy -auto-approve
```

## Reference

```
https://www.youtube.com/watch?v=fpShCxD8kFA
https://github.com/awslabs/amazon-guardduty-tester
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-connection-tracking.html
https://dev.to/aws-builders/aws-incident-response-how-to-contain-an-ec2-instance-pjk
https://github.com/epomatti/aws-cloudwatch-subscriptions
```

[1]: https://console.aws.amazon.com/systems-manager/automation/execute/AWS-QuarantineEC2Instance
[2]: https://docs.aws.amazon.com/guardduty/latest/ug/findings-runtime-monitoring.html#backdoor-runtime-ccactivitybdns
[3]: https://docs.aws.amazon.com/guardduty/latest/ug/findings-runtime-monitoring.html

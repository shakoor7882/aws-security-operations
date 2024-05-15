#!/bin/bash

account=$(aws sts get-caller-identity --query "Account" --output text)
region=us-east-2
sourceImage=quay.io/petr_ruzicka/malware-cryptominer-container:latest
ecrImage=ecr-cryptominer:latest

docker pull $sourceImage
docker tag $sourceImage "$account.dkr.ecr.$region.amazonaws.com/$ecrImage"
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin "$account.dkr.ecr.$region.amazonaws.com"
docker push "$account.dkr.ecr.$region.amazonaws.com/$ecrImage"

#!/bin/bash

COMPONENT=$1

if [ -z "${COMPONENT}" ];  then
  echo "Component Input is Needed"
  exit 1
fi

LID=lt-052cc347f82ccdd5b
LVER=1


DNS_UPDATE() {
  PRIVATEIP=$(aws --region us-east-1 ec2 describe-instances --filters "Name=tag:Name,Values=${COMPONENT}"  | jq .Reservations[].Instances[].PrivateIpAddress | xargs -n1)
  sed -e "s/COMPONENT/${COMPONENT}/" -e "s/IPADDRESS/${PRIVATEIP}/" record.json >/tmp/record.json
  aws route53 change-resource-record-sets --hosted-zone-id Z02002953CVPMGJ4BQ334 --change-batch file:///tmp/record.json | jq
}

 INSTANCE_STATE=$(aws --region us-east-1 ec2 describe-instances --filters "Name=tag:Name,Values=${COMPONENT}"  | jq .Reservations[].Instances[].State.Name | xargs -n1)
  if [ "${INSTANCE_STATE}" = "running" ]; then
    echo "${COMPONENT} Instance already exists!!"
    DNS_UPDATE
    exit 0
  fi

  if [ "${INSTANCE_STATE}" = "stopped" ]; then
    echo "${COMPONENT} Instance already exists!!"
    exit 0
  fi
  echo -n Instance ${COMPONENT} created -IPADDRESS is
  aws --region us-east-1 ec2 run-instances --launch-template LaunchTemplateId=${LID},Version=${LVER}  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${COMPONENT}}]" | jq
  sleep 30
  DNS_UPDATE


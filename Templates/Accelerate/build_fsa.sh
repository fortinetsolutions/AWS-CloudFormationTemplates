#!/usr/bin/env bash -vx
stack1=acceleratefsa
region=ca-central-1
instance_type=m4.xlarge
key=ftntkey_californmia
domain=fortidevelopment.com
fsadns=fortiatp
access="0.0.0.0/0"
privateaccess="10.0.0.0/16"
profile=ftnt

#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack1" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack1" --region "$region" --capabilities CAPABILITY_NAMED_IAM --template-body file://NewVPC_FortiSandbox.template.yaml \
        --parameters ParameterKey=VPCCIDR,ParameterValue=10.0.0.0/16 \
         ParameterKey=PublicSubnetCIDR,ParameterValue=10.0.0.0/20 \
         ParameterKey=PrivateSubnetCIDR,ParameterValue=10.0.16.0/20 \
         ParameterKey=AZForSubnets,ParameterValue="$region"a \
         ParameterKey=FortiSandboxEC2Type,ParameterValue="$instance_type" \
         ParameterKey=FortiSandboxPublicENIip,ParameterValue=10.0.0.100 \
         ParameterKey=FortiSandboxPrivateENIip,ParameterValue=10.0.16.100 \
         ParameterKey=DomainName,ParameterValue="$domain" \
         ParameterKey=FSADNSPrefix,ParameterValue="$fsadns" \
         ParameterKey=KeyPair,ParameterValue="$key" \
         ParameterKey=CIDRForInstanceAccess,ParameterValue="$access"
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=10; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack1" |wc -l`
    if [ "${count}" -ne "0" ]
    then
        break
    fi
    echo $c
    sleep 30
done

#
# end of script
#

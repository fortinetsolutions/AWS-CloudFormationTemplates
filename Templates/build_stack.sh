#!/usr/bin/env bash -vx
stack1=acceleratebase
stack2=addprivatelinux
stack3=addpubliclinux
stack4=acceleratefgt
region=us-west-2
instance_type=m3.medium
key=mdwadmin-oregon
domain="fortimdw.com"
fgtdns="fortias"
httpsdns="httpserver"
access="0.0.0.0/0"

#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack1" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack" --region "$region" --template-body file://NewVPC_BaseSetup.template \
        --parameters ParameterKey=VPCCIDR,ParameterValue=10.0.0.0/16 \
         ParameterKey=Public2Subnet,ParameterValue=10.0.2.0/24 \
         ParameterKey=Public1Subnet,ParameterValue=10.0.0.0/24 \
         ParameterKey=Private2Subnet,ParameterValue=10.0.3.0/24 \
         ParameterKey=Private1Subnet,ParameterValue=10.0.1.0/24 \
         ParameterKey=AZForSubnet2,ParameterValue="$region"c \
         ParameterKey=AZForSubnet1,ParameterValue="$region"a
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
# Pull the outputs from the first template
#
tfile=$(mktemp /tmp/foo.XXXXXXXXX)
aws cloudformation --region us-west-2 describe-stacks --stack-name "$stack1" --output text --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
VPC=`cat $tfile|grep ^VPCID|cut -f2 -d$'\t'`
AZ1=`cat $tfile|grep ^AZ1|cut -f2 -d$'\t'`
AZ2=`cat $tfile|grep ^AZ2|cut -f2 -d$'\t'`
SUBNET1=`cat $tfile|grep ^SubnetID1|cut -f2 -d$'\t'`
SUBNET2=`cat $tfile|grep ^SubnetID2|cut -f2 -d$'\t'`
SUBNET3=`cat $tfile|grep ^SubnetID3|cut -f2 -d$'\t'`
SUBNET4=`cat $tfile|grep ^SubnetID4|cut -f2 -d$'\t'`
cat $tfile
if [ -f $tfile ]
then
    rm -f $tfile
fi

#
# Now deploy linux instances in the private subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack2" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack2" --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_WebLinuxInstances.template \
        --parameters    ParameterKey=VPCID,ParameterValue="$VPC" \
                    ParameterKey=AZForInstance1,ParameterValue="$AZ1" \
                    ParameterKey=AZForInstance2,ParameterValue="$AZ2" \
                    ParameterKey=Public1Subnet,ParameterValue="$SUBNET3" \
                    ParameterKey=Public2Subnet,ParameterValue="$SUBNET4" \
                    ParameterKey=CIDRForInstanceAccess,ParameterValue="$access" \
                    ParameterKey=InstanceType,ParameterValue="$instance_type" \
                    ParameterKey=KeyPair,ParameterValue="$key"
fi
#
# Now deploy linux instances in the public subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack3" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack3" --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_AddLinuxInstances.template \
        --parameters    ParameterKey=VPCID,ParameterValue="$VPC" \
                    ParameterKey=AZForInstance1,ParameterValue="$AZ1" \
                    ParameterKey=AZForInstance2,ParameterValue="$AZ2" \
                    ParameterKey=Public1Subnet,ParameterValue="$SUBNET1" \
                    ParameterKey=Public2Subnet,ParameterValue="$SUBNET2" \
                    ParameterKey=CIDRForInstanceAccess,ParameterValue="$access" \
                    ParameterKey=InstanceType,ParameterValue="$instance_type" \
                    ParameterKey=KeyPair,ParameterValue="$key"
fi

count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack4" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack4" --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_Fortigate542_Autoscale_ELB_WorkerNode.template \
        --parameters    ParameterKey=ASGroupMaxSize,ParameterValue=5 \
                        ParameterKey=ASKeyPair,ParameterValue="$key" \
                        ParameterKey=ASQueue,ParameterValue="$stack4"q \
                        ParameterKey=AZForFirewall1,ParameterValue="$AZ1" \
                        ParameterKey=AZForFirewall2,ParameterValue="$AZ2" \
                        ParameterKey=CIDRForASAccess,ParameterValue="$access" \
                        ParameterKey=CIDRForFortiGateAccess,ParameterValue="$access" \
                        ParameterKey=FortiGateInstanceType,ParameterValue="$instance_type" \
                        ParameterKey=FortiGateKeyPair,ParameterValue="$key" \
                        ParameterKey=DomainName,ParameterValue="$domain" \
                        ParameterKey=FGTDNSPrefix,ParameterValue="$fgtdns" \
                        ParameterKey=HTTPSDNSPrefix,ParameterValue="$httpsdns" \
                        ParameterKey=HealthCheckPort,ParameterValue=541 \
                        ParameterKey=HealthCheckPort,ParameterValue=541 \
                        ParameterKey=InitialFortiGateInstanceType,ParameterValue="$instance_type" \
                        ParameterKey=InternalHealthCheckPort,ParameterValue=80 \
                        ParameterKey=InternalListenerPort,ParameterValue=80 \
                        ParameterKey=ListenerPort,ParameterValue=80 \
                        ParameterKey=Private1Subnet,ParameterValue="$SUBNET2" \
                        ParameterKey=Private2Subnet,ParameterValue="$SUBNET4" \
                        ParameterKey=Public1Subnet,ParameterValue="$SUBNET1" \
                        ParameterKey=Public2Subnet,ParameterValue="$SUBNET3" \
                        ParameterKey=ScaleDownThreshold,ParameterValue=40 \
                        ParameterKey=ScaleUpThreshold,ParameterValue=80 \
                        ParameterKey=ScalingParameter,ParameterValue=CPUUtilization \
                        ParameterKey=ScalingPeriod,ParameterValue=300 \
                        ParameterKey=VPCID,ParameterValue="$VPC"
fi

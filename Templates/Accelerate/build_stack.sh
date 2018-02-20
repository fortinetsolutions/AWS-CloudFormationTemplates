#!/usr/bin/env bash
stack1=acceleratebase
stack2=addprivatelinux
stack3=addpubliclinux
stack4=acceleratefgt
stack5=accelerateautoscale
stack6=acceleratefortimanager
stack7=acceleratefortianalyzer
region=us-west-1
instance_type=c4.large
key=ftntkey_californmia
health_check_port=22
domain=fortidevelopment.com
fgtdns=fortias
fmgrprefix=fortimanager
fazprefix=fortianalyzer
webdns=httpserver
access="0.0.0.0/0"
privateaccess="10.0.0.0/16"
config_bucket=accelerate-config
config_object=current.conf
asq=accelerateq


usage()
{
cat << EOF
usage: $0 options

This script will deploy a series of cloudformation templates that build and protect a workload

OPTIONS:
   -k pause for keyboard input
EOF
}

while getopts k OPTION
do
     case $OPTION in
         k)
             KI_SPECIFIED=true
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [ "${KI_SPECIFIED}" == true ]
then
    read -n1 -r -p "Press space to continue with VPC Base Template Deployment..." keypress
fi

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack1" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack1" Template"
fi


#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack1" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack1" --region "$region" --template-body file://NewVPC_BaseSetup.yaml \
        --parameters ParameterKey=VPCCIDR,ParameterValue=10.0.0.0/16 \
         ParameterKey=Public2Subnet,ParameterValue=10.0.2.0/24 \
         ParameterKey=Public1Subnet,ParameterValue=10.0.0.0/24 \
         ParameterKey=Private2Subnet,ParameterValue=10.0.3.0/24 \
         ParameterKey=Private1Subnet,ParameterValue=10.0.1.0/24 \
         ParameterKey=AZForSubnet2,ParameterValue="$region"c \
         ParameterKey=AZForSubnet1,ParameterValue="$region"a > /dev/null
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
    sleep 30
done

if [ "${KI_SPECIFIED}" == true ]
then
    read -n1 -r -p "Press space to continue with Web Server Deployment..." keypress
fi

#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack1.XXXXXXXXX)
aws cloudformation --region "$region" describe-stacks --stack-name "$stack1" --output text --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
VPC=`cat $tfile|grep ^VPCID|cut -f2 -d$'\t'`
AZ1=`cat $tfile|grep ^AZ1|cut -f2 -d$'\t'`
AZ2=`cat $tfile|grep ^AZ2|cut -f2 -d$'\t'`
SUBNET1=`cat $tfile|grep ^SubnetID1|cut -f2 -d$'\t'`
SUBNET2=`cat $tfile|grep ^SubnetID2|cut -f2 -d$'\t'`
SUBNET3=`cat $tfile|grep ^SubnetID3|cut -f2 -d$'\t'`
SUBNET4=`cat $tfile|grep ^SubnetID4|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack2" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack2" Template"
fi

#
# Now deploy linux web server instances in the private subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack2" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack2" --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_WebLinuxInstances.yaml \
        --parameters    ParameterKey=VPCID,ParameterValue="$VPC" \
                    ParameterKey=AZForInstance1,ParameterValue="$AZ1" \
                    ParameterKey=AZForInstance2,ParameterValue="$AZ2" \
                    ParameterKey=Private1Subnet,ParameterValue="$SUBNET2" \
                    ParameterKey=Private2Subnet,ParameterValue="$SUBNET4" \
                    ParameterKey=CIDRForInstanceAccess,ParameterValue="$access" \
                    ParameterKey=InstanceType,ParameterValue="$instance_type" \
                    ParameterKey=KeyPair,ParameterValue="$key" \
                    ParameterKey=HealthCheckPort,ParameterValue="$health_check_port" \
                    ParameterKey=DomainName,ParameterValue="$domain" \
                    ParameterKey=WebDNSPrefix,ParameterValue="$webdns" >/dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
if [ "${KI_SPECIFIED}" == true ]
then
    for (( c=1; c<=10; c++ ))
    do
        count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack2" |wc -l`
        if [ "${count}" -ne "0" ]
        then
            break
        fi
        sleep 30
    done
fi

if [ "${KI_SPECIFIED}" == true ]
then
    read -n1 -r -p "Press space to continue with Public Subnet deployments..." keypress
fi

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack3" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack3" Template"
fi

#
# Now deploy linux traffic generator instances in the public subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack3" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack3" --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_AddLinuxInstances.yaml \
        --parameters    ParameterKey=VPCID,ParameterValue="$VPC" \
                    ParameterKey=AZForInstance1,ParameterValue="$AZ1" \
                    ParameterKey=AZForInstance2,ParameterValue="$AZ2" \
                    ParameterKey=Public1Subnet,ParameterValue="$SUBNET1" \
                    ParameterKey=Public2Subnet,ParameterValue="$SUBNET3" \
                    ParameterKey=CIDRForInstanceAccess,ParameterValue="$access" \
                    ParameterKey=CIDRForInternalAccess,ParameterValue="$privateaccess" \
                    ParameterKey=InstanceType,ParameterValue="$instance_type" \
                    ParameterKey=KeyPair,ParameterValue="$key" > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=10; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack3" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep 30
done

if [ "${KI_SPECIFIED}" == true ]
then
    read -n1 -r -p "Press space to deploy Fortigates..." keypress
fi

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack4" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack4" Template"
fi

#
# Now deploy fortigate autoscaling instances in the public & private subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack4" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack4" --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_AddFortigates.yaml \
        --parameters    ParameterKey=S3ConfigObject,ParameterValue="$config_object" \
                        ParameterKey=S3ConfigBucket,ParameterValue="$config_bucket" \
                        ParameterKey=CIDRForFortiGateAccess,ParameterValue="$access" \
                        ParameterKey=FortiGateEC2Type,ParameterValue="$instance_type" \
                        ParameterKey=HealthCheckPort,ParameterValue=541 \
                        ParameterKey=DomainName,ParameterValue="$domain" \
                        ParameterKey=FGTDNSPrefix,ParameterValue="$fgtdns" \
                        ParameterKey=SubnetID2,ParameterValue="$SUBNET2" \
                        ParameterKey=SubnetID4,ParameterValue="$SUBNET4" \
                        ParameterKey=SubnetID1,ParameterValue="$SUBNET1" \
                        ParameterKey=SubnetID3,ParameterValue="$SUBNET3" \
                        ParameterKey=AZForFirewall1,ParameterValue="$AZ1" \
                        ParameterKey=AZForFirewall2,ParameterValue="$AZ2" \
                        ParameterKey=KeyPair,ParameterValue="$key" \
                        ParameterKey=VPCID,ParameterValue="$VPC" >/dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=10; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack1" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep 30
done


#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=10; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack2" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep 30
done

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=10; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack3" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep 30
done

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=10; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack4" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep 30
done

if [ "${KI_SPECIFIED}" == true ]
then
    read -n1 -r -p "Press space to deploy autoscaling..." keypress
fi

tfile=$(mktemp /tmp/foostack5.XXXXXXXXX)
aws cloudformation --region "$region" describe-stacks --stack-name "$stack4" --output text --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
arn=`cat $tfile|grep ^TargetGroupARN|cut -f2 -d$'\t'`
nlb=`cat $tfile|grep ^PublicElasticLoadBalancer|cut -f2 -d$'\t'`
oda=`cat $tfile|grep ^OnDemandA|cut -f2 -d$'\t'`
odb=`cat $tfile|grep ^OnDemandB|cut -f2 -d$'\t'`

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack5" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack5" Template"
fi

#
# Now deploy fortigate autoscaling instances in the public & private subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack5" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack5" --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_AddAutoscale.yaml \
        --parameters    ParameterKey=CIDRForFGTAccess,ParameterValue="$access" \
                        ParameterKey=FortigateEC2Type,ParameterValue="$instance_type" \
                        ParameterKey=Private1Subnet,ParameterValue="$SUBNET2" \
                        ParameterKey=Private2Subnet,ParameterValue="$SUBNET4" \
                        ParameterKey=Public1Subnet,ParameterValue="$SUBNET1" \
                        ParameterKey=Public2Subnet,ParameterValue="$SUBNET3" \
                        ParameterKey=FortigateKeyPair,ParameterValue="$key" \
                        ParameterKey=ASQueue,ParameterValue="$asq" \
                        ParameterKey=ASKeyPair,ParameterValue="$key" \
                        ParameterKey=CIDRForASAccess,ParameterValue="$access" \
                        ParameterKey=OnDemandA,ParameterValue="$oda" \
                        ParameterKey=OnDemandB,ParameterValue="$odb" \
                        ParameterKey=FortigateStack,ParameterValue="$stack4" \
                        ParameterKey=NetworkLoadBalancer,ParameterValue="$nlb" \
                        ParameterKey=FortigateTargetGroupARN,ParameterValue="$arn" \
                        ParameterKey=VPCID,ParameterValue="$VPC" >/dev/null
fi
cat $tfile
if [ -f $tfile ]
then
    rm -f $tfile
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=10; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack5" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep 30
done

if [ "${KI_SPECIFIED}" == true ]
then
    read -n1 -r -p "Press space to deploy FortiManager..." keypress
fi

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack6" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack6" Template"
fi

count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack6" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack6" --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_AddFortiManager.yaml \
        --parameters    ParameterKey=CIDRForFmgrAccess,ParameterValue="$access" \
                        ParameterKey=DomainName,ParameterValue="$domain" \
                        ParameterKey=FmgrPrefix,ParameterValue="$fmgrprefix" \
                        ParameterKey=FortiManagerEC2Type,ParameterValue="$instance_type" \
                        ParameterKey=FortiManagerKeyPair,ParameterValue="$key" \
                        ParameterKey=FortiManagerSubnet,ParameterValue="$SUBNET2" \
                        ParameterKey=VPCID,ParameterValue="$VPC" >/dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=10; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack6" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep 30
done

if [ "${KI_SPECIFIED}" == true ]
then
    read -n1 -r -p "Press space to deploy FortiAnalyzer..." keypress
fi

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack7" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack7" Template"
fi

count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack7" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack7" --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_AddFortiAnalyzer.yaml \
        --parameters    ParameterKey=CIDRForFazAccess,ParameterValue="$access" \
                        ParameterKey=DomainName,ParameterValue="$domain" \
                        ParameterKey=FazPrefix,ParameterValue="$fazprefix" \
                        ParameterKey=FortiAnalyzerEC2Type,ParameterValue="$instance_type" \
                        ParameterKey=FortiAnalyzerKeyPair,ParameterValue="$key" \
                        ParameterKey=FortiAnalyzerSubnet,ParameterValue="$SUBNET2" \
                        ParameterKey=VPCID,ParameterValue="$VPC" >/dev/null
fi

#
# End of the script
#

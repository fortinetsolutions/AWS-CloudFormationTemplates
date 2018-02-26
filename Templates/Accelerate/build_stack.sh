#!/usr/bin/env bash

source $(dirname $0)/stack_parameters.sh

#
# Extra variables
#

linux_instance_type=c4.large
fgt_instance_type=c4.large
key=ftntkey_californmia
health_check_port=22

access="0.0.0.0/0"
privateaccess="10.0.0.0/16"

asq=$stack_prefix-q
pause=15

usage()
{
cat << EOF
usage: $0 options

This script will deploy a series of cloudformation templates that build and protect a workload

OPTIONS:
   -k pause for keyboard input
   -p pause value between AWS queries
   -W worker node debug
EOF
}

while getopts kp:W OPTION
do
     case $OPTION in
         k)
             KI_SPECIFIED=true
             ;;
         p)
             PAUSE_SPECIFIED=true
             PAUSE_VALUE=$OPTARG
             ;;
         W)
             WORKER_NODE_DEBUG_SPECIFIED=true
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [ "$PAUSE_SPECIFIED" == true ]
then
    pause=$PAUSE_VALUE
fi

if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
while [ $keypress_loop == true ]
do
    echo
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy base vpc..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

echo
echo "Updating Fortigate configuration file used by bootstrapper"
echo

bucket=`aws s3api list-buckets  --output text --region "$region" \
    --query "Buckets[?contains(Name, '$config_bucket')].Name"`
if [ "$bucket" != "$config_bucket" ]
then
    echo "Making bucket $config_bucket"
    aws s3 mb s3://"$config_bucket" --output text --region "$region"
fi

echo "Making http server substitions in fortigate config files for http server name: $webdns"

cp base_current.conf "$config_object"
sed -i "s/{WEB_DNS_NAME}/$webdns/g" $config_object

cp base_current_b.conf "$config_object_b"
sed -i "s/{WEB_DNS_NAME}/$webdns/g" $config_object_b

echo "Copying config file to s3://$config_bucket/$config_object"
echo
aws s3 cp --output text --region "$region" "$config_object" s3://"$config_bucket"/"$config_object"
aws s3 cp --output text --region "$region" "$config_object_b" s3://"$config_bucket"/"$config_object_b"
echo

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack1" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack1" Template"
fi


#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack1" --output text --region "$region" --template-body file://NewVPC_BaseSetup.yaml \
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
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1" |wc -l`
    if [ "${count}" -ne "0" ]
    then
        break
    fi
    sleep $pause
done

#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack1.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack1" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
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

echo
echo "Created VPC = $VPC"
echo "Availability Zone 1 = $AZ1"
echo "Availability Zone 2 = $AZ2"
echo "Subnet 1 = $SUBNET1"
echo "Subnet 2 = $SUBNET2"
echo "Subnet 3 = $SUBNET3"
echo "Subnet 4 = $SUBNET4"
echo

if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
while [ $keypress_loop == true ]
do
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy web servers..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack2" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack2" Template"
fi

#
# Now deploy linux web server instances in the private subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack2" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_WebLinuxInstances.yaml \
        --parameters    ParameterKey=VPCID,ParameterValue="$VPC" \
                    ParameterKey=AZForInstance1,ParameterValue="$AZ1" \
                    ParameterKey=AZForInstance2,ParameterValue="$AZ2" \
                    ParameterKey=Private1Subnet,ParameterValue="$SUBNET2" \
                    ParameterKey=Private2Subnet,ParameterValue="$SUBNET4" \
                    ParameterKey=CIDRForInstanceAccess,ParameterValue="$access" \
                    ParameterKey=InstanceType,ParameterValue="$linux_instance_type" \
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
    for (( c=1; c<=50; c++ ))
    do
        count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2" |wc -l`
        if [ "${count}" -ne "0" ]
        then
            break
        fi
        sleep $pause
    done
fi

tfile=$(mktemp /tmp/foostack5.XXXXXXXXX)
aws cloudformation describe-stacks --stack-name "$stack2" --output text --region "$region" \
    --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
wl1=`cat $tfile|grep ^WebLinux1InstanceID|cut -f2 -d$'\t'`
wl2=`cat $tfile|grep ^WebLinux2InstanceID|cut -f2 -d$'\t'`
wl1_ip=`cat $tfile|grep ^WebLinux1InstanceIP|cut -f2 -d$'\t'`
wl2_ip=`cat $tfile|grep ^WebLinux2InstanceIP|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "WebLinux1 instance id = $wl1 public ip = $wl1_ip"
echo "WebLinux2 instance id = $wl2 public ip = $wl2_ip"
echo

if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
while [ $keypress_loop == true ]
do
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy traffic generators..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack3" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack3" Template"
fi

#
# Now deploy linux traffic generator instances in the public subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack3" --output text --region "$region" \
        --capabilities CAPABILITY_IAM --template-body file://ExistingVPC_AddLinuxInstances.yaml \
        --parameters    ParameterKey=VPCID,ParameterValue="$VPC" \
                    ParameterKey=AZForInstance1,ParameterValue="$AZ1" \
                    ParameterKey=AZForInstance2,ParameterValue="$AZ2" \
                    ParameterKey=Public1Subnet,ParameterValue="$SUBNET1" \
                    ParameterKey=Public2Subnet,ParameterValue="$SUBNET3" \
                    ParameterKey=CIDRForInstanceAccess,ParameterValue="$access" \
                    ParameterKey=CIDRForInternalAccess,ParameterValue="$privateaccess" \
                    ParameterKey=InstanceType,ParameterValue="$linux_instance_type" \
                    ParameterKey=KeyPair,ParameterValue="$key" > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

tfile=$(mktemp /tmp/foostack5.XXXXXXXXX)
aws cloudformation --output text --region "$region" describe-stacks \
    --stack-name "$stack3" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
tg1=`cat $tfile|grep ^TGLinux1InstanceID|cut -f2 -d$'\t'`
tg2=`cat $tfile|grep ^TGLinux2InstanceID|cut -f2 -d$'\t'`
tg1_ip=`cat $tfile|grep ^TGLinux1InstancePublicIP|cut -f2 -d$'\t'`
tg2_ip=`cat $tfile|grep ^TGLinux2InstancePublicIP|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "TGLinux1 instance id = $tg1 public ip = $tg1_ip"
echo "TGLinux2 instance id = $tg2 public ip = $tg2_ip"
echo

if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
while [ $keypress_loop == true ]
do
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy non-autoscaled Fortigates..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack4" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack4" Template"
fi

#
# Now deploy fortigate autoscaling instances in the public & private subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack4" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack4" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_AddFortigates.yaml \
        --parameters    ParameterKey=S3ConfigObject,ParameterValue="$config_object" \
                        ParameterKey=S3ConfigObjectB,ParameterValue="$config_object_b" \
                        ParameterKey=S3ConfigBucket,ParameterValue="$config_bucket" \
                        ParameterKey=CIDRForFortiGateAccess,ParameterValue="$access" \
                        ParameterKey=FortiGateEC2Type,ParameterValue="$fgt_instance_type" \
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
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack4" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

tfile=$(mktemp /tmp/foostack5.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" \
    --stack-name "$stack4" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
arn=`cat $tfile|grep ^TargetGroupARN|cut -f2 -d$'\t'`
nlb=`cat $tfile|grep ^PublicElasticLoadBalancer|cut -f2 -d$'\t'`
oda=`cat $tfile|grep ^OnDemandAID|cut -f2 -d$'\t'`
odb=`cat $tfile|grep ^OnDemandBID|cut -f2 -d$'\t'`
odaip=`cat $tfile|grep ^OnDemandAIP|cut -f2 -d$'\t'`
odbip=`cat $tfile|grep ^OnDemandBIP|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "TargetGroupARN = $arn"
echo "Public Load Balancer = $nlb"
echo "OnDemandA instance id = $oda public ip = $odaip"
echo "OnDemandB instance id = $odb public ip = $odbip"
echo

if [ "$WORKER_NODE_DEBUG_SPECIFIED" == true ]
then
    aws ec2 create-tags --resources "$oda" --tags Key=Fortigate-State,Value=UnConfigured
fi

if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
while [ $keypress_loop == true ]
do
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy autoscaling..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done


if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack5" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack5" Template"
fi

#
# Now deploy fortigate autoscaling instances in the public & private subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack5" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack5" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_AddAutoscale.yaml \
        --parameters    ParameterKey=CIDRForFGTAccess,ParameterValue="$access" \
                        ParameterKey=FortigateEC2Type,ParameterValue="$fgt_instance_type" \
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

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack5" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

tfile=$(mktemp /tmp/foostack5.XXXXXXXXX)
aws cloudformation describe-stacks --stack-name "$stack5" --output text --region "$region" \
    --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
asid=`cat $tfile|grep ^ASInstanceID|cut -f2 -d$'\t'`
asip=`cat $tfile|grep ^ASInstanceIP|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "ASInstance instance id = $asid public ip = $asip"
echo

#if [ "$WORKER_NODE_DEBUG_SPECIFIED" == true ]
#then
#    sudo cat /etc/hosts | grep -v awswn > /etc/hosts
#    sudo echo "$asid awswn" >> /etc/hosts
#fi

if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
while [ $keypress_loop == true ]
do
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy FortiManager..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack6" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack6" Template"
fi

count=`aws cloudformation list-stacks --output text --region "$region" --stack-status-filter CREATE_COMPLETE |grep "$stack6" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack6" --output text --region "$region" \
        --capabilities CAPABILITY_IAM --template-body file://ExistingVPC_AddFortiManager.yaml \
        --parameters    ParameterKey=CIDRForFmgrAccess,ParameterValue="$access" \
                        ParameterKey=DomainName,ParameterValue="$domain" \
                        ParameterKey=FmgrPrefix,ParameterValue="$fmgrprefix" \
                        ParameterKey=FortiManagerEC2Type,ParameterValue="$fgt_instance_type" \
                        ParameterKey=FortiManagerKeyPair,ParameterValue="$key" \
                        ParameterKey=FortiManagerSubnet,ParameterValue="$SUBNET2" \
                        ParameterKey=VPCID,ParameterValue="$VPC" >/dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --output text --region "$region" --stack-status-filter CREATE_COMPLETE |grep "$stack6" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

tfile=$(mktemp /tmp/foostack6.XXXXXXXXX)
aws cloudformation describe-stacks --stack-name "$stack6" \
    --output text --region "$region" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
fmgrid=`cat $tfile|grep ^FortiManager|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

tfile=$(mktemp /tmp/foostackeipalloc.XXXXXXXXX)
aws ec2 allocate-address --output text --region "$region" --domain vpc > $tfile
eip=`cat $tfile|grep ^eipalloc|cut -f1 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi


tfile=$(mktemp /tmp/foostackdesribe.XXXXXXXXX)
aws ec2 describe-instances --instance-id "$oda" --output text --region "$region" --filter  \
    --query 'Reservations[*].Instances[*].NetworkInterfaces[*].{Desc:Description,ID:NetworkInterfaceId}' >$tfile
eni=`cat $tfile|grep ^eth0|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "FortiManager - Associate EIP $eip instance id $oda interface $eni"

#
# Allocate a public IP for the FortiManager and save it in public ip
#
aws ec2 associate-address --output text --region "$region" --network-interface-id "$eni" \
    --allocation-id "$eip" --allow-reassociation --private-ip-address 10.0.0.253 >/dev/null

publicip=`aws ec2 describe-addresses --output text --region "$region" --allocation-id $eip --query "Addresses[*].{PublicIp:PublicIp}"`
#
# Find the hosted zone id for the domain we are using
#

hosted_zone_id=`aws route53 list-hosted-zones --output text --region "$region" --query "HostedZones[?contains(Name, '$domain.')].{Id:Id}"`
echo "FortiManager public ip $publicip allocated for domain $fmgrprefix.$domain"
fmgpip=$publicip
if [ -e create_route53_resource.json ]
then
    #
    # Create a route53 resource batch file to create an ALIAS record set for the FortiManager Public IP
    #
    tfile=$(mktemp /tmp/foostack53.XXXXXXXXX)
    cp create_route53_resource.json $tfile
    sed -i "s/{ACTION}/UPSERT/g" $tfile
    sed -i "s/{COMMENT}/FortiManager DNS Name/g" $tfile
    sed -i "s/{DOMAIN}/$domain/g" $tfile
    sed -i "s/{DNSPREFIX}/$fmgrprefix/g" $tfile
    sed -i "s/{IPADDRESS}/$publicip/g" $tfile

    echo
    echo "Change record set batch file"
    aws route53 change-resource-record-sets --output text --region "$region" --hosted-zone-id $hosted_zone_id --change-batch file://$tfile
    if [ -f $tfile ]
    then
        rm -f $tfile
    fi
fi

fgtpip=`aws ec2 describe-instances --instance-id $oda \
    --region $region --output text --query "Reservations[*].Instances[*].[PrivateIpAddress]"`

echo "Sleeping for 30 seconds to allow FMG to boot."
echo $fmgpip
sleep 30

curl -sk --request POST --url https://lambda.fortiengineering.com/fmg \
--header 'Accept: application/json' \
--header 'Cache-Control: no-cache' \
--data '{
"fgtName": "fgt-OnDemandA",
"fgtIp": "'$fgtpip'",
"fgtAdmin": "admin",
"fgtPass": "'$oda'",
"fmgIp": "'$fmgpip'",
"fmgAdmin": "admin",
"fmgPass": "'$fmgrid'",
"fmgAdom": "root"
}'

echo
echo

if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi

while [ $keypress_loop == true ]
do
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy FortiAnalyzer..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack7" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack7" Template"
fi

count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack7" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack7" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_AddFortiAnalyzer.yaml \
        --parameters    ParameterKey=CIDRForFazAccess,ParameterValue="$access" \
                        ParameterKey=DomainName,ParameterValue="$domain" \
                        ParameterKey=FazPrefix,ParameterValue="$fazprefix" \
                        ParameterKey=FortiAnalyzerEC2Type,ParameterValue="$fgt_instance_type" \
                        ParameterKey=FortiAnalyzerKeyPair,ParameterValue="$key" \
                        ParameterKey=FortiAnalyzerSubnet,ParameterValue="$SUBNET2" \
                        ParameterKey=VPCID,ParameterValue="$VPC" >/dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack7" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

tfile=$(mktemp /tmp/foostack5.XXXXXXXXX)
aws cloudformation describe-stacks --stack-name "$stack7" \
    --output text --region "$region" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
fazid=`cat $tfile|grep ^FortiAnalyzer|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

tfile=$(mktemp /tmp/foostackeipalloc.XXXXXXXXX)
aws ec2 allocate-address --output text --region "$region" --domain vpc > $tfile
eip=`cat $tfile|grep ^eipalloc|cut -f1 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi


tfile=$(mktemp /tmp/foostackdesribe.XXXXXXXXX)
aws ec2 describe-instances --instance-id "$oda" --output text --region "$region" --filter  \
    --query 'Reservations[*].Instances[*].NetworkInterfaces[*].{Desc:Description,ID:NetworkInterfaceId}' >$tfile
eni=`cat $tfile|grep ^eth0|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "FortiAnalyzer - Associate EIP $eip instance id $oda interface $eni"

#
# Allocate a public IP for the FortiAnalyzer and save it in public ip
#
aws ec2 associate-address --network-interface-id --output text --region "$region" "$eni" \
    --allocation-id "$eip" --allow-reassociation --private-ip-address 10.0.0.252 >/dev/null

publicip=`aws ec2 describe-addresses --output text --region "$region" --allocation-id $eip --query "Addresses[*].{PublicIp:PublicIp}"`

#
# Find the hosted zone id for the domain we are using
#

hosted_zone_id=`aws route53 list-hosted-zones --output text --region "$region" --query "HostedZones[?contains(Name, '$domain.')].{Id:Id}"`
echo "FortiAnalyzer public ip $publicip allocated for domain $fazprefix.$domain"
fazpip=$publicip
if [ -e create_route53_resource.json ]
then
    #
    # Create a route53 resource batch file to create an ALIAS record set for the FortiManager Public IP
    #
    tfile=$(mktemp /tmp/foostack53.XXXXXXXXX)
    cp create_route53_resource.json $tfile
    sed -i "s/{ACTION}/UPSERT/g" $tfile
    sed -i "s/{COMMENT}/FortiAnalyzer DNS Name/g" $tfile
    sed -i "s/{DOMAIN}/$domain/g" $tfile
    sed -i "s/{DNSPREFIX}/$fazprefix/g" $tfile
    sed -i "s/{IPADDRESS}/$publicip/g" $tfile

    echo
    echo "Change record set batch file"
    aws route53 change-resource-record-sets --output text --region "$region" --hosted-zone-id $hosted_zone_id --change-batch file://$tfile
    if [ -f $tfile ]
    then
        rm -f $tfile
    fi
fi

echo "Sleeping for 30 seconds to allow FAZ to boot."
echo $fmgpip
echo $fazpip
sleep 30

curl -sk --request POST --url https://lambda.fortiengineering.com/faz \
--header 'Accept: application/json' \
--header 'Cache-Control: no-cache' \
--data '{
"fgtName": "fgt-OnDemandA",
"fgtIp": "'$fgtpip'",
"fmgIp": "'$fmgpip'",
"fmgAdmin": "admin",
"fmgPass": "'$fmgrid'",
"fazIp": "'$fazpip'",
"fazAdmin": "admin",
"fazPass": "'$fazid'",
"fazAdom": "root"
}'
#
# End of the script
#

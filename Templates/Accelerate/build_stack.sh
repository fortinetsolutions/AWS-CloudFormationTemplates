#!/usr/bin/env bash
stack1=acceleratebase
stack2=addprivatelinux
stack3=addpubliclinux
stack4=acceleratefgt
stack5=accelerateautoscale
stack6=acceleratefortimanager
stack7=acceleratefortianalyzer
region=us-west-1
linux_instance_type=c4.large
fgt_instance_type=c4.large
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
config_object_b=current-b.conf
asq=accelerateq
pause=15

usage()
{
cat << EOF
usage: $0 options

This script will deploy a series of cloudformation templates that build and protect a workload

OPTIONS:
   -k pause for keyboard input
   -p pause value between AWS queries
EOF
}

while getopts kp: OPTION
do
     case $OPTION in
         k)
             KI_SPECIFIED=true
             ;;
         p)
             PAUSE_SPECIFIED=true
             PAUSE_VALUE=$OPTARG
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
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy base vpc..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

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
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack1" |wc -l`
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
        count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack2" |wc -l`
        if [ "${count}" -ne "0" ]
        then
            break
        fi
        sleep $pause
    done
fi

tfile=$(mktemp /tmp/foostack5.XXXXXXXXX)
aws cloudformation --region "$region" describe-stacks \
    --stack-name "$stack2" --output text --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
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

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack3" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack3" Template"
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
                    ParameterKey=InstanceType,ParameterValue="$linux_instance_type" \
                    ParameterKey=KeyPair,ParameterValue="$key" > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack3" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

tfile=$(mktemp /tmp/foostack5.XXXXXXXXX)
aws cloudformation --region "$region" describe-stacks \
    --stack-name "$stack3" --output text --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
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

echo "Updating Fortigate configuration file used by bootstrapper"

bucket=`aws s3api list-buckets  --query "Buckets[?contains(Name, '$config_bucket')].Name"`
if [ "$bucket" != "$config_bucket" ]
then
    echo "Making bucket $config_bucket"
    aws s3 mb s3://"$config_bucket" --region "$region"
fi
echo "Copying config file to s3://$config_bucket/$config_object"
aws s3 cp "$config_object" s3://"$config_bucket"/"$config_object"
aws s3 cp "$config_object_b" s3://"$config_bucket"/"$config_object_b"
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
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack4" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

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

tfile=$(mktemp /tmp/foostack5.XXXXXXXXX)
aws cloudformation --region "$region" describe-stacks --stack-name "$stack4" --output text --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
arn=`cat $tfile|grep ^TargetGroupARN|cut -f2 -d$'\t'`
nlb=`cat $tfile|grep ^PublicElasticLoadBalancer|cut -f2 -d$'\t'`
oda=`cat $tfile|grep ^OnDemandA|cut -f2 -d$'\t'`
odb=`cat $tfile|grep ^OnDemandB|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "TargetGroupARN = $arn"
echo "Public Load Balancer = $nlb"
echo "OnDemandA instance id = $oda"
echo "OnDemandB instance id = $odb"
echo

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
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack5" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

tfile=$(mktemp /tmp/foostack5.XXXXXXXXX)
aws cloudformation --region "$region" describe-stacks --stack-name "$stack5" --output text --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
asid=`cat $tfile|grep ^ASInstanceID|cut -f2 -d$'\t'`
asip=`cat $tfile|grep ^ASInstanceIP|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "ASInstance instance id = $asid public ip = $asip"
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

count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack6" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack6" --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_AddFortiManager.yaml \
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
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack6" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

tfile=$(mktemp /tmp/foostackeipalloc.XXXXXXXXX)
aws ec2 allocate-address --domain vpc > $tfile
eip=`cat $tfile|grep ^eipalloc|cut -f1 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi


tfile=$(mktemp /tmp/foostackdesribe.XXXXXXXXX)
aws ec2 describe-instances --instance-id "$oda" --output text --filter  \
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
aws ec2 associate-address --network-interface-id "$eni" \
    --allocation-id "$eip" --allow-reassociation --private-ip-address 10.0.0.253 >/dev/null

publicip=`aws ec2 describe-addresses --allocation-id $eip --query "Addresses[*].{PublicIp:PublicIp}"`


#
# Find the hosted zone id for the domain we are using
#

hosted_zone_id=`aws route53 list-hosted-zones --query "HostedZones[?contains(Name, '$domain.')].{Id:Id}"`
echo "$publicip allocated for FortiManager for domain $domain hosted zone id $hosted_zone_id"
if [ -e create_route53_resource.json ]
then
    #
    # Create a route53 resource batch file to create an ALIAS record set for the FortiManager Public IP
    #
    tfile=$(mktemp /tmp/foostack53.XXXXXXXXX)
    cp create_route53_resource.json $tfile
    sed -i -- "s/{COMMENT}/FortiManager DNS Name/g" $tfile
    sed -i -- "s/{DOMAIN}/$domain/g" $tfile
    sed -i -- "s/{DNSPREFIX}/fortimanager/g" $tfile
    sed -i -- "s/{IPADDRESS}/$publicip/g" $tfile

    echo
    echo "Change record set batch file"
    aws route53 change-resource-record-sets --hosted-zone-id $hosted_zone_id --change-batch file://$tfile
    if [ -f $tfile ]
    then
        rm -f $tfile
    fi
fi

#curl -H "Content-Type: application/json" -X POST -d '{"fortimanager":"10.0.","password":"xyz"}' http://localhost:3000/api/login

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

count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack7" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack7" --region "$region" --capabilities CAPABILITY_IAM \
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
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" |grep "$stack7" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done


tfile=$(mktemp /tmp/foostackeipalloc.XXXXXXXXX)
aws ec2 allocate-address --domain vpc > $tfile
eip=`cat $tfile|grep ^eipalloc|cut -f1 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi


tfile=$(mktemp /tmp/foostackdesribe.XXXXXXXXX)
aws ec2 describe-instances --instance-id "$oda" --output text --filter  \
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
aws ec2 associate-address --network-interface-id "$eni" \
    --allocation-id "$eip" --allow-reassociation --private-ip-address 10.0.0.252 >/dev/null

publicip=`aws ec2 describe-addresses --allocation-id $eip --query "Addresses[*].{PublicIp:PublicIp}"`


#
# Find the hosted zone id for the domain we are using
#

hosted_zone_id=`aws route53 list-hosted-zones --query "HostedZones[?contains(Name, '$domain.')].{Id:Id}"`
echo "$publicip allocated for FortiAnalyzer for domain $domain hosted zone id $hosted_zone_id"
if [ -e create_route53_resource.json ]
then
    #
    # Create a route53 resource batch file to create an ALIAS record set for the FortiManager Public IP
    #
    tfile=$(mktemp /tmp/foostack53.XXXXXXXXX)
    cp create_route53_resource.json $tfile
    sed -i -- "s/{COMMENT}/FortiAnalyzer DNS Name/g" $tfile
    sed -i -- "s/{DOMAIN}/$domain/g" $tfile
    sed -i -- "s/{DNSPREFIX}/fortianalyzer/g" $tfile
    sed -i -- "s/{IPADDRESS}/$publicip/g" $tfile

    echo
    echo "Change record set batch file"
    aws route53 change-resource-record-sets --hosted-zone-id $hosted_zone_id --change-batch file://$tfile
    if [ -f $tfile ]
    then
        rm -f $tfile
    fi
fi
#
# End of the script
#

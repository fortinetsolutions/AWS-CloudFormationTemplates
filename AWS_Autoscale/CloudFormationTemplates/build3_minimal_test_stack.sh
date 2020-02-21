#!/usr/bin/env bash

source $(dirname $0)/stack_parameters.sh

#
# Extra variables
#

project_name=$stack_prefix-autoscale
linux_instance_type=c4.large
fgt_instance_type=c5.large
key=mdw-poc-common
clear_text_password=
password_secret=mdw_password
health_check_port=22
alb_listener_port=80
alb_target_group_port=8001
nlb_listener_port=514
nlb_target_group_port=514
scale_up_threshold=70
scale_down_threshold=20

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

echo "Copying config file to s3://$config_bucket/$config_object"
echo
aws s3 cp --output text --region "$region" "$config_object" s3://"$config_bucket"/"$config_object"
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
    aws cloudformation create-stack --stack-name "$stack1" --output text --region "$region" \
        --template-body file://NewVPC_Base_3Zones.yaml \
        --parameters ParameterKey=VPCCIDR,ParameterValue=10.0.0.0/16 \
         ParameterKey=Public3Subnet,ParameterValue=10.0.4.0/24 \
         ParameterKey=Public2Subnet,ParameterValue=10.0.2.0/24 \
         ParameterKey=Public1Subnet,ParameterValue=10.0.0.0/24 \
         ParameterKey=Private3Subnet,ParameterValue=10.0.5.0/24 \
         ParameterKey=Private2Subnet,ParameterValue=10.0.3.0/24 \
         ParameterKey=Private1Subnet,ParameterValue=10.0.1.0/24 \
         ParameterKey=AZForSubnet3,ParameterValue="$region"c \
         ParameterKey=AZForSubnet2,ParameterValue="$region"b \
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
VPCCIDR=`cat $tfile|grep ^VPCCIDR|cut -f2 -d$'\t'`
AZ1=`cat $tfile|grep ^AZ1|cut -f2 -d$'\t'`
AZ2=`cat $tfile|grep ^AZ2|cut -f2 -d$'\t'`
AZ3=`cat $tfile|grep ^AZ3|cut -f2 -d$'\t'`
SUBNET1=`cat $tfile|grep ^SubnetID1|cut -f2 -d$'\t'`
SUBNET2=`cat $tfile|grep ^SubnetID2|cut -f2 -d$'\t'`
SUBNET3=`cat $tfile|grep ^SubnetID3|cut -f2 -d$'\t'`
SUBNET4=`cat $tfile|grep ^SubnetID4|cut -f2 -d$'\t'`
SUBNET5=`cat $tfile|grep ^SubnetID5|cut -f2 -d$'\t'`
SUBNET6=`cat $tfile|grep ^SubnetID6|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Created VPC = $VPC"
echo "VPC Cidr Block = $VPCCIDR"
echo "Availability Zone 1 = $AZ1"
echo "Availability Zone 2 = $AZ2"
echo "Availability Zone 3 = $AZ3"
echo "Subnet 1 = $SUBNET1"
echo "Subnet 2 = $SUBNET2"
echo "Subnet 3 = $SUBNET3"
echo "Subnet 4 = $SUBNET4"
echo "Subnet 5 = $SUBNET5"
echo "Subnet 6 = $SUBNET6"
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
    read -n1 -r -p "Press enter to deploy autoscaling framework..." keypress
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
# Now deploy lambda function and API gateway framework
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack5" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack5" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://AutoScale_Automation-Framework.json \
        --parameters ParameterKey=ProjectName,ParameterValue=$project_name \
         ParameterKey=Environment,ParameterValue=$environment_tag \
         ParameterKey=BucketName,ParameterValue=$lambda_bucket >/dev/null
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
apiurl=`cat $tfile|grep ^AutoScaleAPIURL|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "API URL = "$apiurl""
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
    read -n1 -r -p "Press enter to deploy autoscaling group..." keypress
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

#
# Now deploy fortigate autoscaling instances in the public & private subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack6" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack6" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://FGT_AutoScale_ExistingVPC_Paygo_3Zones.json \
        --parameters    ParameterKey=VPCID,ParameterValue="$VPC" \
                        ParameterKey=VPCCIDR,ParameterValue="$VPCCIDR" \
                        ParameterKey=PublicSubnet1,ParameterValue="$SUBNET1" \
                        ParameterKey=PrivateSubnet1,ParameterValue="$SUBNET2" \
                        ParameterKey=PublicSubnet2,ParameterValue="$SUBNET3" \
                        ParameterKey=PrivateSubnet2,ParameterValue="$SUBNET4" \
                        ParameterKey=PublicSubnet3,ParameterValue="$SUBNET5" \
                        ParameterKey=PrivateSubnet3,ParameterValue="$SUBNET6" \
                        ParameterKey=CIDRForInstanceAccess,ParameterValue="$access" \
                        ParameterKey=AdminHttpsPort,ParameterValue="$admin_port" \
                        ParameterKey=KeyPair,ParameterValue="$key" \
                        ParameterKey=SsmSecureStringParamName,ParameterValue="$password_secret" \
                        ParameterKey=InitS3Bucket,ParameterValue="$license_bucket" \
                        ParameterKey=InternalLBDNSName,ParameterValue="$lb_dns_name" \
                        ParameterKey=AlbListenerPort,ParameterValue="$alb_listener_port" \
                        ParameterKey=AlbTargetGroupPort,ParameterValue="$alb_target_group_port" \
                        ParameterKey=NlbListenerPort,ParameterValue="$nlb_listener_port" \
                        ParameterKey=NlbTargetGroupPort,ParameterValue="$nlb_target_group_port" \
                        ParameterKey=APIGatewayURL,ParameterValue="$apiurl" \
                        ParameterKey=EnvironmentTag,ParameterValue="$environment_tag" \
                        ParameterKey=ScaleUpThreshold,ParameterValue=$scale_up_threshold \
                        ParameterKey=ScaleDownThreshold,ParameterValue=$scale_down_threshold \
                        ParameterKey=ASGPAYGMinSize,ParameterValue=1 \
                        ParameterKey=PAYGInstanceType,ParameterValue="$fgt_instance_type" \
                        ParameterKey=ASGPAYGMaxSize,ParameterValue=5 > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack6" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

tfile=$(mktemp /tmp/foostack6.XXXXXXXXX)
aws cloudformation describe-stacks --stack-name "$stack6" --output text --region "$region" \
    --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
username=`cat $tfile|grep ^Username|cut -f2 -d$'\t'`
ssm_name=`cat $tfile|grep ^SsmParameterName|cut -f2 -d$'\t'`
external_alb=`cat $tfile|grep ^Alb|cut -f2 -d$'\t'`
external_nlb=`cat $tfile|grep ^Nlb|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Fortigate Username = "$username""
echo "Ssm Parameter Name = "$ssm_name""
echo "External Application Load Balancer = "$external_alb""
echo "External Network Load Balancer = "$external_nlb""
echo

#
# End of the script
#

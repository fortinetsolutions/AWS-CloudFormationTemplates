#!/usr/bin/env bash 

source $(dirname $0)/stack_parameters.sh
sed_tool=sed
#
# Extra variables
#

linux_instance_type=c4.large
fgt_instance_type=c5.large
key=mdw-key-oregon
password_secret=Fortigate/Admin/Password
health_check_port=22
listener_port=80
environment_tag=prod
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
   -L turn the deployment of Traffic Generators and Web Servers
EOF
}

while getopts kHPLp: OPTION
do
     case $OPTION in
         k)
             KI_SPECIFIED=true
             ;;
         p)
             PAUSE_SPECIFIED=true
             PAUSE_VALUE=$OPTARG
             ;;
         H)
             #
             # Turn on the deployment of Hybrid License Autoscale Group
             #
             DEPLOY_HYBRID_ASG_SPECIFIED=true
             ;;
         P)
             #
             # Turn on the deployment of Paygo Only Autoscale Group
             #
             DEPLOY_PAYGO_ASG_SPECIFIED=true
             ;;
         L)
             #
             # Turn on the deployment of Web Servers and Traffic Generators
             #
             DEPLOY_LINUX_INSTANCES_SPECIFIED=true
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

if [ "$machine" == "Mac" ]
then
    sed_tool="gsed"
fi

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
$sed_tool -i "s/{WEB_DNS_NAME}/$webdns/g" $config_object
$sed_tool -i "s/{DOMAIN}/$domain/g" $config_object

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
VPCCIDR=`cat $tfile|grep ^VPCCIDR|cut -f2 -d$'\t'`
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
echo "VPC Cidr Block = $VPCCIDR"
echo "Availability Zone 1 = $AZ1"
echo "Availability Zone 2 = $AZ2"
echo "Subnet 1 = $SUBNET1"
echo "Subnet 2 = $SUBNET2"
echo "Subnet 3 = $SUBNET3"
echo "Subnet 4 = $SUBNET4"
echo

if [ "$DEPLOY_LINUX_INSTANCES_SPECIFIED" == true ]
then
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
                        ParameterKey=HealthCheckPort,ParameterValue="$health_check_port"  \
                        ParameterKey=DomainName,ParameterValue="$domain" \
                        ParameterKey=WebDNSPrefix,ParameterValue="$webdns" >/dev/null
    fi

    #
    # Wait for template above to CREATE_COMPLETE
    #
    for (( c=1; c<=50; c++ ))
    do
        count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2" |wc -l`
        if [ "${count}" -ne "0" ]
        then
            break
        fi
        sleep $pause
    done


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
        if [ "${count}" -ne "0" ]
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
# Now deploy fortigate autoscaling instances in the public & private subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack5" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack5" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://AutoScale_Automation-Framework.yaml   >/dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack5" |wc -l`
    if [ "${count}" -ne "0" ]
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

if [ "$DEPLOY_HYBRID_ASG_SPECIFIED" == true ]
then
    if [ "$KI_SPECIFIED" == true ]
    then
        keypress_loop=true
    else
        keypress_loop=false
    fi
    while [ $keypress_loop == true ]
    do
        read -t 1 -n 10000 discard
        read -n1 -r -p "Press enter to deploy hybrid licensing autoscaling group..." keypress
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
            --template-body file://FGT_AutoScale_ExistingVPC_Hybrid-Licensing.yaml \
            --parameters    ParameterKey=VPCID,ParameterValue="$VPC" \
                            ParameterKey=VPCCIDR,ParameterValue="$VPCCIDR" \
                            ParameterKey=PublicSubnet1,ParameterValue="$SUBNET1" \
                            ParameterKey=PrivateSubnet1,ParameterValue="$SUBNET2" \
                            ParameterKey=PublicSubnet2,ParameterValue="$SUBNET3" \
                            ParameterKey=PrivateSubnet2,ParameterValue="$SUBNET4" \
                            ParameterKey=CIDRForInstanceAccess,ParameterValue="$access" \
                            ParameterKey=AdminHttpsPort,ParameterValue="$admin_port" \
                            ParameterKey=KeyPair,ParameterValue="$key" \
                            ParameterKey=FortiOSVersion,ParameterValue="$fortios_version" \
                            ParameterKey=SsmSecureStringParamName,ParameterValue="$password_parameter_name" \
                            ParameterKey=InitS3Bucket,ParameterValue="$license_bucket" \
                            ParameterKey=InternalLBDNSName,ParameterValue="$lb_dns_name" \
                            ParameterKey=NlbListenerPort,ParameterValue="$listener_port" \
                            ParameterKey=APIGatewayURL,ParameterValue="$apiurl" \
                            ParameterKey=EnvironmentTag,ParameterValue="$environment_tag" \
                            ParameterKey=ScaleUpThreshold,ParameterValue=$scale_up_threshold \
                            ParameterKey=ScaleDownThreshold,ParameterValue=$scale_down_threshold \
                            ParameterKey=BYOLInstanceType,ParameterValue="$fgt_instance_type" \
                            ParameterKey=ASGBYOLMinSize,ParameterValue=1 \
                            ParameterKey=ASGBYOLMaxSize,ParameterValue=2 \
                            ParameterKey=PAYGInstanceType,ParameterValue="$fgt_instance_type" \
                            ParameterKey=ASGPAYGMinSize,ParameterValue=0 \
                            ParameterKey=ASGPAYGMaxSize,ParameterValue=5 > /dev/null
    fi

    #
    # Wait for template above to CREATE_COMPLETE
    #
    for (( c=1; c<=50; c++ ))
    do
        count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack6" |wc -l`
        if [ "${count}" -ne "0" ]
        then
            break
        fi
        sleep $pause
    done

    tfile=$(mktemp /tmp/foostack6.XXXXXXXXX)
    aws cloudformation describe-stacks --stack-name "$stack6" --output text --region "$region" \
        --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
    username=`cat $tfile|grep ^Username|cut -f2 -d$'\t'`
    ssm_parameter_name=`cat $tfile|grep ^SsmParameterName|cut -f2 -d$'\t'`
    alb=`cat $tfile|grep ^Alb|cut -f2 -d$'\t'`
    nlb=`cat $tfile|grep ^Nlb|cut -f2 -d$'\t'`
    if [ -f $tfile ]
    then
        rm -f $tfile
    fi

    echo
    echo "User Name = $username"
    echo "Ssm Parameter Name = $ssm_parameter_name"
    echo "Application Load Balancer = $alb"
    echo "Network Load Balancer = $nlb"
    echo
fi

if [ "$DEPLOY_PAYGO_ASG_SPECIFIED" == true ]
then
    if [ "$KI_SPECIFIED" == true ]
    then
        keypress_loop=true
    else
        keypress_loop=false
    fi
    while [ $keypress_loop == true ]
    do
        read -t 1 -n 10000 discard
        read -n1 -r -p "Press enter to deploy paygo autoscaling group..." keypress
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

    #
    # Now deploy fortigate autoscaling instances in the public & private subnets on top of the existing VPC
    #

    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack7" |wc -l`
    if [ "${count}" -eq "0" ]
    then
        aws cloudformation create-stack --stack-name "$stack7" --output text --region "$region" --capabilities CAPABILITY_IAM \
            --template-body file://FGT_AutoScale_ExistingVPC_Paygo.yaml \
            --parameters    ParameterKey=VPCID,ParameterValue="$VPC" \
                            ParameterKey=VPCCIDR,ParameterValue="$VPCCIDR" \
                            ParameterKey=PublicSubnet1,ParameterValue="$SUBNET1" \
                            ParameterKey=PrivateSubnet1,ParameterValue="$SUBNET2" \
                            ParameterKey=PublicSubnet2,ParameterValue="$SUBNET3" \
                            ParameterKey=PrivateSubnet2,ParameterValue="$SUBNET4" \
                            ParameterKey=CIDRForInstanceAccess,ParameterValue="$access" \
                            ParameterKey=AdminHttpsPort,ParameterValue="$admin_port" \
                            ParameterKey=KeyPair,ParameterValue="$key" \
                            ParameterKey=FortiOSVersion,ParameterValue="$fortios_version" \
                            ParameterKey=SsmSecureStringParamName,ParameterValue="$password_parameter_name" \
                            ParameterKey=InitS3Bucket,ParameterValue="$license_bucket" \
                            ParameterKey=InternalLBDNSName,ParameterValue="$lb_dns_name" \
                            ParameterKey=NlbListenerPort,ParameterValue="$listener_port" \
                            ParameterKey=APIGatewayURL,ParameterValue="$apiurl" \
                            ParameterKey=EnvironmentTag,ParameterValue="$environment_tag" \
                            ParameterKey=ScaleUpThreshold,ParameterValue=$scale_up_threshold \
                            ParameterKey=ScaleDownThreshold,ParameterValue=$scale_down_threshold \
                            ParameterKey=PAYGInstanceType,ParameterValue="$fgt_instance_type" \
                            ParameterKey=ASGPAYGMinSize,ParameterValue=0 \
                            ParameterKey=ASGPAYGMaxSize,ParameterValue=5 > /dev/null
    fi

    #
    # Wait for template above to CREATE_COMPLETE
    #
    for (( c=1; c<=50; c++ ))
    do
        count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack7" |wc -l`
        if [ "${count}" -ne "0" ]
        then
            break
        fi
        sleep $pause
    done

    tfile=$(mktemp /tmp/foostack7.XXXXXXXXX)
    aws cloudformation describe-stacks --stack-name "$stack7" --output text --region "$region" \
        --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
    username=`cat $tfile|grep ^Username|cut -f2 -d$'\t'`
    ssm_parameter_name=`cat $tfile|grep ^SsmParameterName|cut -f2 -d$'\t'`
    alb_paygo=`cat $tfile|grep ^Albpaygo|cut -f2 -d$'\t'`
    nlb_paygo=`cat $tfile|grep ^Nlbpaygo|cut -f2 -d$'\t'`
    if [ -f $tfile ]
    then
        rm -f $tfile
    fi

    echo
    echo "User Name = $username"
    echo "Ssm Parameter Name = $ssm_parameter_name"
    echo "Application Load Balancer = $alb-paygo"
    echo "Network Load Balancer = $nlb-paygo"
    echo
fi
#
# End of the script
#

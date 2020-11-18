#!/usr/bin/env bash

source $(dirname $0)/stack_parameters_option1.sh

pause=15

make_s3 ()
{
    if [ -z "$1" ]
    then
        echo "No bucket specified"
        return -1
    fi
    if [ -z "$2" ]
    then
        echo "No license specified"
        return -1
    fi
    url=$3

    bucket=$1
    file=$2
    found_bucket=0
    for b in `aws s3 ls|cut -f3 -d' '`
    do
        if [ "$bucket" == "$b" ]
        then
            found_bucket=1
            break
        fi
    done
    if [ $found_bucket == 1 ]
    then
        aws s3 mb s3://$bucket
        aws s3 cp $file s3://$bucket
    fi
    return 0
}

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
    read -n1 -r -p "Press enter to deploy base security vpc..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

make_s3 $license_bucket $fortigate1_license_file
make_s3 $license_bucket $fortigate2_license_file

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack1s" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack1s" Template"
fi


#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1s" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack1s" --output text --region "$region" \
        --template-body file://BaseVPC_Dual_AZ_option1.yaml \
        --parameters ParameterKey=VPCCIDR,ParameterValue="$ha_cidr" \
         ParameterKey=AZForSubnet1,ParameterValue="$region"a \
         ParameterKey=AZForSubnet2,ParameterValue="$region"c \
         ParameterKey=PublicSubnet1,ParameterValue="$ha_public1_subnet" \
         ParameterKey=PrivateSubnet1,ParameterValue="$ha_private1_subnet" \
         ParameterKey=PublicSubnet2,ParameterValue="$ha_public2_subnet" \
         ParameterKey=PrivateSubnet2,ParameterValue="$ha_private2_subnet" \
         ParameterKey=HASyncSubnet1,ParameterValue="$ha_sync1_subnet" \
         ParameterKey=HASyncSubnet2,ParameterValue="$ha_sync2_subnet" \
         ParameterKey=HAMgmtSubnet1,ParameterValue="$ha_mgmt1_subnet" \
         ParameterKey=HAMgmtSubnet2,ParameterValue="$ha_mgmt2_subnet" > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1s" |wc -l`
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
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack1s" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
VPC=`cat $tfile|grep ^VPCID|cut -f2 -d$'\t'`
VPCCIDR=`cat $tfile|grep ^VPCCIDR|cut -f2 -d$'\t'`
AZ1=`cat $tfile|grep ^AZ1|cut -f2 -d$'\t'`
AZ2=`cat $tfile|grep ^AZ2|cut -f2 -d$'\t'`
Public1_SUBNET=`cat $tfile|grep ^Public1ID|cut -f2 -d$'\t'`
Private1_SUBNET=`cat $tfile|grep ^Private1ID|cut -f2 -d$'\t'`
HASync1_SUBNET=`cat $tfile|grep ^HASync1ID|cut -f2 -d$'\t'`
HAMgmt1_SUBNET=`cat $tfile|grep ^HAMgmt1ID|cut -f2 -d$'\t'`
Public2_SUBNET=`cat $tfile|grep ^Public2ID|cut -f2 -d$'\t'`
Private2_SUBNET=`cat $tfile|grep ^Private2ID|cut -f2 -d$'\t'`
HASync2_SUBNET=`cat $tfile|grep ^HASync2ID|cut -f2 -d$'\t'`
HAMgmt2_SUBNET=`cat $tfile|grep ^HAMgmt2ID|cut -f2 -d$'\t'`
PublicRouteTableID=`cat $tfile|grep ^PublicRouteTableID|cut -f2 -d$'\t'`
PrivateRouteTable1ID=`cat $tfile|grep ^PrivateRouteTable1ID|cut -f2 -d$'\t'`
PrivateRouteTable2ID=`cat $tfile|grep ^PrivateRouteTable2ID|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Created VPC = $VPC"
echo "VPC Cidr Block = $VPCCIDR"
echo "Availability Zone 1 = $AZ1"
echo "Availability Zone 2 = $AZ2"
echo "Public Subnet 1 = $Public1_SUBNET"
echo "Private Subnet 1 = $Private1_SUBNET"
echo "HASync Subnet 1 = $HASync1_SUBNET"
echo "HAMgmt Subnet 1 = $HAMgmt1_SUBNET"
echo "Public Subnet 2 = $Public2_SUBNET"
echo "Private Subnet 2 = $Private2_SUBNET"
echo "HASync Subnet 2 = $HASync2_SUBNET"
echo "HAMgmt Subnet 2 = $HAMgmt2_SUBNET"
echo "Public Route Table ID = $PublicRouteTableID"
echo "Private Route Table 1 ID = $PrivateRouteTable1ID"
echo "Private Route Table  2 ID = $PrivateRouteTable2ID"
echo

#
# Deploy Security VPC AGW (AGW_ExistingVPC.yaml)
#
if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
while [ $keypress_loop == true ]
do
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy Gateway Loadbalancer (Gwlb_ExistingVPC.yaml)..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done


if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack2b" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack2b" Template"
fi

#
# Now deploy Gateway Lood Balancer in private subnets on top of the existing VPC
#

count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2b" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack2b" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://Gwlb_ExistingVPC.yaml \
        --parameters    ParameterKey=GwlbName,ParameterValue="$gwlb_name" \
                        ParameterKey=GwlbSubnets,ParameterValue=\"$Private1_SUBNET,$Private2_SUBNET\" > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2b" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack2.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack2b" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
GWLB_ARN=`cat $tfile|grep ^SpGwlbArn|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Gateway LoadBalancer ARN = $GWLB_ARN"
echo

lb_info_line=$(aws ec2 describe-network-interfaces --region "$region" --filter "Name=subnet-id,Values=$Private1_SUBNET" --output text --query 'NetworkInterfaces[?contains(Description, `-gateway-lb`) == `true`].[PrivateIpAddress,NetworkInterfaceId,Description]')
lb_ip_address1=`echo $lb_info_line | cut -d ' ' -f1`
if [[ $lb_ip_address1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
    echo "Load Balancer IP Address in AZ 1 = $lb_ip_address1"
else
    echo "Load Balancer does not have a valid IP address: $lb_ip_address1"
    exit
fi
lb_info_line=$(aws ec2 describe-network-interfaces --region "$region" --filter "Name=subnet-id,Values=$Private2_SUBNET" --output text --query 'NetworkInterfaces[?contains(Description, `-gateway-lb`) == `true`].[PrivateIpAddress,NetworkInterfaceId,Description]')
lb_ip_address2=`echo $lb_info_line | cut -d ' ' -f1`
if [[ $lb_ip_address2 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
    echo "Load Balancer IP Address in AZ 2 = $lb_ip_address2"
else
    echo "Load Balancer does not have a valid IP address: $lb_ip_address2"
    exit
fi

#
# Deploy Security VPC Fortigate's (Fortigate_ExistingVPC.yaml)
#
if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
while [ $keypress_loop == true ]
do
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy Gateway LoadBalancer high availability FortiGate group..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done


if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack2a" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack2a" Template"
fi


#
# Now deploy fortigate HA instances in the public & private subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2a" |wc -l`
if [ "${count}" -eq "0" ]
then
    #
    # Recalculate the Fortigate 1 and 2 Private IP addresses, if they conflict with the GWLB IP address
    #
    host_ip=`echo "$fortigate1_private_ip"|cut -f1 -d"/"`
    subnet_bits=`echo "$fortigate1_public_ip"|cut -f2 -d"/"`
    if [ "$host_ip" == "$lb_ip_address1" ]
    then
        echo "Host IP Conflict ($host_ip) with LoadBalancer 2 IP address ($lb_ip_address1)"
        net="$(echo $host_ip |cut -d. -f1-3)"
        host="$(echo $host_ip | cut -d. -f4)"
        host=$(( $host +1))
        fortigate1_private_ip="$(echo $net.$host/$subnet_bits)"
        echo "Changing Fortigate 1 Private IP to $fortigate1_private_ip"
    else
        echo "No Load Balancer IP conflict in Private 1 Subnet"
    fi
    host_ip=`echo "$fortigate2_private_ip"|cut -f1 -d"/"`
    subnet_bits=`echo "$fortigate2_public_ip"|cut -f2 -d"/"`
    if [ "$host_ip" == "$lb_ip_address2" ]
    then
        echo "Host IP Conflict ($host_ip) with LoadBalancer 2 IP address ($lb_ip_address2)"
        net="$(echo $host_ip |cut -d. -f1-3)"
        host="$(echo $host_ip | cut -d. -f4)"
        host=$(( $host +1))
        fortigate2_private_ip="$(echo $net.$host/$subnet_bits)"
        echo "Changing Fortigate 2 Private IP to $fortigate2_private_ip"
    else
        echo "No Load Balancer IP conflict in Private 2 Subnet"
    fi
    aws cloudformation create-stack --stack-name "$stack2a" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://Fortigate_ExistingVPC_option1.yaml \
        --parameters    ParameterKey=VPCID,ParameterValue="$VPC" \
                        ParameterKey=VPCCIDR,ParameterValue="$VPCCIDR" \
                        ParameterKey=PublicRouteTableID,ParameterValue="$PublicRouteTableID" \
                        ParameterKey=Public1Subnet,ParameterValue="$Public1_SUBNET" \
                        ParameterKey=Private1Subnet,ParameterValue="$Private1_SUBNET" \
                        ParameterKey=HASync1Subnet,ParameterValue="$HASync1_SUBNET" \
                        ParameterKey=HAMgmt1Subnet,ParameterValue="$HAMgmt1_SUBNET" \
                        ParameterKey=Public2Subnet,ParameterValue="$Public2_SUBNET" \
                        ParameterKey=Private2Subnet,ParameterValue="$Private2_SUBNET" \
                        ParameterKey=HASync2Subnet,ParameterValue="$HASync2_SUBNET" \
                        ParameterKey=HAMgmt2Subnet,ParameterValue="$HAMgmt2_SUBNET" \
                        ParameterKey=InstanceType,ParameterValue="$fgt_instance_type" \
                        ParameterKey=CIDRForInstanceAccess,ParameterValue="$access_public" \
                        ParameterKey=AZ1,ParameterValue="$AZ1" \
                        ParameterKey=AZ2,ParameterValue="$AZ2" \
                        ParameterKey=KeyPair,ParameterValue="$key" \
                        ParameterKey=AdminPw,ParameterValue="$admin_password" \
                        ParameterKey=InitS3Bucket,ParameterValue="$license_bucket" \
                        ParameterKey=InitS3BucketRegion,ParameterValue="$region" \
                        ParameterKey=LicenseType,ParameterValue="$license_type" \
                        ParameterKey=FortiGate1LicenseFile,ParameterValue="$fortigate1_license_file" \
                        ParameterKey=FortiGate2LicenseFile,ParameterValue="$fortigate2_license_file" \
                        ParameterKey=Public1SubnetRouterIP,ParameterValue="$public1_subnet_router" \
                        ParameterKey=Private1SubnetRouterIP,ParameterValue="$private1_subnet_router" \
                        ParameterKey=HAMgmt1SubnetRouterIP,ParameterValue="$ha_mgmt1_subnet_router" \
                        ParameterKey=Public2SubnetRouterIP,ParameterValue="$public2_subnet_router" \
                        ParameterKey=Private2SubnetRouterIP,ParameterValue="$private2_subnet_router" \
                        ParameterKey=HAMgmt2SubnetRouterIP,ParameterValue="$ha_mgmt2_subnet_router" \
                        ParameterKey=LoadBalancerIP1,ParameterValue="$lb_ip_address1" \
                        ParameterKey=LoadBalancerIP2,ParameterValue="$lb_ip_address2" \
                        ParameterKey=FortiGate1PrivateCIDR,ParameterValue="$ha_private1_subnet" \
                        ParameterKey=FortiGate1PublicIP,ParameterValue="$fortigate1_public_ip" \
                        ParameterKey=FortiGate1PrivateIP,ParameterValue="$fortigate1_private_ip" \
                        ParameterKey=FortiGate1HAsyncIP,ParameterValue="$fortigate1_sync_ip" \
                        ParameterKey=FortiGate1HAmgmtIP,ParameterValue="$fortigate1_mgmt_ip" \
                        ParameterKey=FortiGate2PrivateCIDR,ParameterValue="$ha_private2_subnet" \
                        ParameterKey=FortiGate2PublicIP,ParameterValue="$fortigate2_public_ip" \
                        ParameterKey=FortiGate2PrivateIP,ParameterValue="$fortigate2_private_ip" \
                        ParameterKey=FortiGate2HAsyncIP,ParameterValue="$fortigate2_sync_ip" \
                        ParameterKey=FortiGate2HAmgmtIP,ParameterValue="$fortigate2_mgmt_ip" > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2a" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack2.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack2a" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
CLUSTER_URL=`cat $tfile|grep ^ClusterLoginURL|cut -f2 -d$'\t'`
Fortigate1_Login_URL=`cat $tfile|grep ^FortiGate1LoginURL|cut -f2 -d$'\t'`
Fortigate2_Login_URL=`cat $tfile|grep ^FortiGate2LoginURL|cut -f2 -d$'\t'`
Fortigate_Password=`cat $tfile|grep ^Password|cut -f2 -d$'\t'`
Fortigate_Username=`cat $tfile|grep ^Username|cut -f2 -d$'\t'`
Fortigate1PublicENI=`cat $tfile|grep ^FortiGate1PublicENI|cut -f2 -d$'\t'`
Fortigate2PublicENI=`cat $tfile|grep ^FortiGate2PublicENI|cut -f2 -d$'\t'`
Fortigate1PrivateENI=`cat $tfile|grep ^FortiGate1PrivateENI|cut -f2 -d$'\t'`
Fortigate2PrivateENI=`cat $tfile|grep ^FortiGate2PrivateENI|cut -f2 -d$'\t'`
Fortigate1PrivateIP=`cat $tfile|grep ^FortiGate1PrivateIP|cut -f2 -d$'\t'`
Fortigate2PrivateIP=`cat $tfile|grep ^FortiGate2PrivateIP|cut -f2 -d$'\t'`
Fortigate1InstanceId=`cat $tfile|grep ^InstanceId1|cut -f2 -d$'\t'`
Fortigate2InstanceId=`cat $tfile|grep ^InstanceId2|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Cluster Login URL = $CLUSTER_URL"
echo "Fortigate 1 Login URL = $Fortigate1_Login_URL"
echo "Fortigate 2 Login URL = $Fortigate2_Login_URL"
echo "Fortigate Password = $Fortigate_Password"
echo "Fortigate Username = $Fortigate_Username"
echo "Fortigate 1 Public ENI ID = $Fortigate1PublicENI"
echo "Fortigate 2 Public ENI ID = $Fortigate2PublicENI"
echo "Fortigate 1 Private ENI ID = $Fortigate1PrivateENI"
echo "Fortigate 2 Private ENI ID = $Fortigate2PrivateENI"
echo "Fortigate 1 Private IP = $Fortigate1PrivateIP"
echo "Fortigate 2 Private IP = $Fortigate2PrivateIP"
echo "Fortigate 1 Instance ID = $Fortigate1InstanceId"
echo "Fortigate 2 Instance ID = $Fortigate2InstanceId"
echo
#
# Fix the private route table and point default route to the ENI of Fortigate 1
#
echo
echo "Changing Default Route (0.0.0.0/0) of Private Route Table 1 $PrivateRouteTable1ID to use ENI of Fortigate 1 ($Fortigate1PrivateENI)"
aws ec2 replace-route --region "$region" --route-table-id "$PrivateRouteTable1ID" --destination-cidr-block 0.0.0.0/0 --network-interface-id "$Fortigate1PrivateENI"
echo "Changing Default Route (0.0.0.0/0) of Private Route Table 2 $PrivateRouteTable2ID to use ENI of Fortigate 1 ($Fortigate1PrivateENI)"
aws ec2 replace-route --region "$region" --route-table-id "$PrivateRouteTable2ID" --destination-cidr-block 0.0.0.0/0 --network-interface-id "$Fortigate1PrivateENI"
echo

#
# Deploy Security VPC AGW Target Group (AGW_Tg_Existing.yaml)
#
if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
while [ $keypress_loop == true ]
do
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy Gateway LoadBalancer Target Group (Gwlb_Tg_Existing.yaml)..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done


if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack2btg" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack2btg" Template"
fi

#
# Now deploy fortigate HA instances in the public & private subnets on top of the existing VPC
#

count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2btg" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack2btg" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://Gwlb_Tg_Existing.yaml \
        --parameters    ParameterKey=GwlbArn,ParameterValue="$GWLB_ARN" \
                        ParameterKey=TargetGroupName,ParameterValue="$gwlb_target_group_name" \
                        ParameterKey=TargetGroupPort,ParameterValue="$gwlb_target_group_port" \
                        ParameterKey=HealthPort,ParameterValue="$gwlb_health_port" \
                        ParameterKey=HealthProtocol,ParameterValue="$gwlb_health_protocol" \
                        ParameterKey=VpcId,ParameterValue="$VPC" \
                        ParameterKey=Appliance1IP,ParameterValue="$Fortigate1PrivateIP" \
                        ParameterKey=Appliance2IP,ParameterValue="$Fortigate2PrivateIP" > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2btg" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack2.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack2btg" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
GWLB_TG_ARN=`cat $tfile|grep ^SpTgArn|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Gateway LoadBalancer ARN = $GWLB_ARN"
echo "Gateway LoadBalancer Target Group ARN = $GWLB_TG_ARN"
echo


#
# Deploy VPCe Service Name
#
if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
while [ $keypress_loop == true ]
do
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy VPCe Service Name ..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done


if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack2c" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack2c" Template"
fi

#
# Now deploy VPCe Service Name
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2c" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack2c" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://AWS_VPC_Endpoint_Service.yaml \
        --parameters    ParameterKey=GwlbArn,ParameterValue="$GWLB_ARN" \
                        ParameterKey=AcceptConnection,ParameterValue=$AcceptConnection \
                        ParameterKey=AwsAccountToWhitelist,ParameterValue="$AwsAccountToWhitelist" > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2c" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack2.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack2c" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
Vpce_Service_Id=`cat $tfile|grep ^SpVpcEndpointServiceId|cut -f2 -d$'\t'`
Vpce_Service_Name=`cat $tfile|grep ^SpVpcEndpointServiceName|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "VPCe Service ID = $Vpce_Service_Id"
echo "VPCe Service Name = $Vpce_Service_Name"
echo

#
# Deploy Customer A VPC
#
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
    read -n1 -r -p "Press enter to deploy customer A, B, C vpcs..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack1a" Template and the script will pause when the create-stack is complete"
    echo "Deploying "$stack1b" Template and the script will pause when the create-stack is complete"
    echo "Deploying "$stack1c" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack1a" Template"
    echo "Deploying "$stack1b" Template"
    echo "Deploying "$stack1c" Template"
fi


#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1a" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack1a" --output text --region "$region" \
        --template-body file://BaseVPC_Customer_option1.yaml \
        --parameters ParameterKey=VPCCIDR,ParameterValue="$customer_a_cidr" \
         ParameterKey=PublicSubnet,ParameterValue="$customer_a_public_subnet" \
         ParameterKey=PrivateSubnet,ParameterValue="$customer_a_private_subnet" \
         ParameterKey=AZ,ParameterValue="$customer_a_az" > /dev/null
fi


#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1b" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack1b" --output text --region "$region" \
        --template-body file://BaseVPC_Customer_option1.yaml \
        --parameters ParameterKey=VPCCIDR,ParameterValue="$customer_b_cidr" \
         ParameterKey=PublicSubnet,ParameterValue="$customer_b_public_subnet" \
         ParameterKey=PrivateSubnet,ParameterValue="$customer_b_private_subnet" \
         ParameterKey=AZ,ParameterValue="$customer_b_az" > /dev/null
fi


#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1c" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack1c" --output text --region "$region" \
        --template-body file://BaseVPC_Customer_option1.yaml \
        --parameters ParameterKey=VPCCIDR,ParameterValue="$customer_c_cidr" \
         ParameterKey=PublicSubnet,ParameterValue="$customer_c_public_subnet" \
         ParameterKey=PrivateSubnet,ParameterValue="$customer_c_private_subnet" \
         ParameterKey=AZ,ParameterValue="$customer_c_az" > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1a" |wc -l`
    if [ "${count}" -ne "0" ]
    then
        break
    fi
    sleep $pause
done


#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1b" |wc -l`
    if [ "${count}" -ne "0" ]
    then
        break
    fi
    sleep $pause
done


#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1c" |wc -l`
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
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack1a" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
CA_VPC=`cat $tfile|grep ^VPCID|cut -f2 -d$'\t'`
CA_VPCCIDR=`cat $tfile|grep ^VPCCIDR|cut -f2 -d$'\t'`
CA_AZ=`cat $tfile|grep ^AZ|cut -f2 -d$'\t'`
CA_Public_SUBNET=`cat $tfile|grep ^PublicID|cut -f2 -d$'\t'`
CA_PublicRouteTableID=`cat $tfile|grep ^PublicRouteTableID|cut -f2 -d$'\t'`
CA_Private_SUBNET=`cat $tfile|grep ^PrivateID|cut -f2 -d$'\t'`
CA_PrivateRouteTableID=`cat $tfile|grep ^PrivateRouteTableID|cut -f2 -d$'\t'`
CA_IgwRouteTableID=`cat $tfile|grep ^IgwRouteTableID|cut -f2 -d$'\t'`
CA_InternetGatewayID=`cat $tfile|grep ^InternetGatewayID|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Created VPC = $CA_VPC"
echo "VPC Cidr Block = $CA_VPCCIDR"
echo "Availability Zone = $CA_AZ"
echo "Public Subnet = $CA_Public_SUBNET"
echo "Public Route Table ID = $CA_PublicRouteTableID"
echo "Private Subnet = $CA_Private_SUBNET"
echo "Private Route Table ID = $CA_PrivateRouteTableID"
echo "Igw Route Table ID = $CA_IgwRouteTableID"
echo "Internet Gateway ID = $CA_InternetGatewayID"
echo


#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack1.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack1b" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
CB_VPC=`cat $tfile|grep ^VPCID|cut -f2 -d$'\t'`
CB_VPCCIDR=`cat $tfile|grep ^VPCCIDR|cut -f2 -d$'\t'`
CB_AZ=`cat $tfile|grep ^AZ|cut -f2 -d$'\t'`
CB_Public_SUBNET=`cat $tfile|grep ^PublicID|cut -f2 -d$'\t'`
CB_PublicRouteTableID=`cat $tfile|grep ^PublicRouteTableID|cut -f2 -d$'\t'`
CB_Private_SUBNET=`cat $tfile|grep ^PrivateID|cut -f2 -d$'\t'`
CB_PrivateRouteTableID=`cat $tfile|grep ^PrivateRouteTableID|cut -f2 -d$'\t'`
CB_IgwRouteTableID=`cat $tfile|grep ^IgwRouteTableID|cut -f2 -d$'\t'`
CB_InternetGatewayID=`cat $tfile|grep ^InternetGatewayID|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Created VPC = $CB_VPC"
echo "VPC Cidr Block = $CB_VPCCIDR"
echo "Availability Zone = $CB_AZ"
echo "Public Subnet = $CB_Public_SUBNET"
echo "Public Route Table ID = $CB_PublicRouteTableID"
echo "Private Subnet = $CB_Private_SUBNET"
echo "Private Route Table ID = $CB_PrivateRouteTableID"
echo "Igw Route Table ID = $CB_IgwRouteTableID"
echo "Internet Gateway ID = $CB_InternetGatewayID"
echo


#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack1.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack1c" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
CC_VPC=`cat $tfile|grep ^VPCID|cut -f2 -d$'\t'`
CC_VPCCIDR=`cat $tfile|grep ^VPCCIDR|cut -f2 -d$'\t'`
CC_AZ=`cat $tfile|grep ^AZ|cut -f2 -d$'\t'`
CC_Public_SUBNET=`cat $tfile|grep ^PublicID|cut -f2 -d$'\t'`
CC_PublicRouteTableID=`cat $tfile|grep ^PublicRouteTableID|cut -f2 -d$'\t'`
CC_Private_SUBNET=`cat $tfile|grep ^PrivateID|cut -f2 -d$'\t'`
CC_PrivateRouteTableID=`cat $tfile|grep ^PrivateRouteTableID|cut -f2 -d$'\t'`
CC_IgwRouteTableID=`cat $tfile|grep ^IgwRouteTableID|cut -f2 -d$'\t'`
CC_InternetGatewayID=`cat $tfile|grep ^InternetGatewayID|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Created VPC = $CC_VPC"
echo "VPC Cidr Block = $CC_VPCCIDR"
echo "Availability Zone = $CC_AZ"
echo "Public Subnet = $CC_Public_SUBNET"
echo "Public Route Table ID = $CC_PublicRouteTableID"
echo "Private Subnet = $CC_Private_SUBNET"
echo "Private Route Table ID = $CC_PrivateRouteTableID"
echo "Igw Route Table ID = $CC_IgwRouteTableID"
echo "Internet Gateway ID = $CC_InternetGatewayID"
echo

#
# DEPLOY CUSTOMER A,B, C VPC Endpoints and Linux Instances
#
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
    read -n1 -r -p "Press enter to deploy customer A, B, C vpc endpoint and Linux Instances..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack3a1" Template and the script will pause when the create-stack is complete"
    echo "Deploying "$stack3b1" Template and the script will pause when the create-stack is complete"
    echo "Deploying "$stack3c1" Template and the script will pause when the create-stack is complete"
    echo "Deploying "$stack3a" Template and the script will pause when the create-stack is complete"
    echo "Deploying "$stack3b" Template and the script will pause when the create-stack is complete"
    echo "Deploying "$stack3c" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack3a1" Template"
    echo "Deploying "$stack3b1" Template"
    echo "Deploying "$stack3c1" Template"
    echo "Deploying "$stack3a" Template"
    echo "Deploying "$stack3b" Template"
    echo "Deploying "$stack3c" Template"
fi


#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3a1" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack3a1" --output text --region "$region" \
        --template-body file://AWS_VPC_Endpoint_Existing_option1.yaml \
        --parameters ParameterKey=VpcId,ParameterValue="$CA_VPC" \
         ParameterKey=VpceSubnetId,ParameterValue="$CA_Public_SUBNET" \
         ParameterKey=PrivateRouteTableId,ParameterValue="$CA_PrivateRouteTableID" \
         ParameterKey=IgwRouteTableId,ParameterValue="$CA_IgwRouteTableID" \
         ParameterKey=PrivateSubnetCidr,ParameterValue="$customer_a_private_subnet" \
         ParameterKey=ServiceName,ParameterValue="$Vpce_Service_Name" > /dev/null
fi


#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3b1" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack3b1" --output text --region "$region" \
        --template-body file://AWS_VPC_Endpoint_Existing_option1.yaml \
        --parameters ParameterKey=VpcId,ParameterValue="$CB_VPC" \
         ParameterKey=VpceSubnetId,ParameterValue="$CB_Public_SUBNET" \
         ParameterKey=PrivateRouteTableId,ParameterValue="$CB_PrivateRouteTableID" \
         ParameterKey=IgwRouteTableId,ParameterValue="$CB_IgwRouteTableID" \
         ParameterKey=PrivateSubnetCidr,ParameterValue="$customer_b_private_subnet" \
         ParameterKey=ServiceName,ParameterValue="$Vpce_Service_Name" > /dev/null
fi


#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3c1" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack3c1" --output text --region "$region" \
        --template-body file://AWS_VPC_Endpoint_Existing_option1.yaml \
        --parameters ParameterKey=VpcId,ParameterValue="$CC_VPC" \
         ParameterKey=VpceSubnetId,ParameterValue="$CC_Public_SUBNET" \
         ParameterKey=PrivateRouteTableId,ParameterValue="$CC_PrivateRouteTableID" \
         ParameterKey=IgwRouteTableId,ParameterValue="$CC_IgwRouteTableID" \
         ParameterKey=PrivateSubnetCidr,ParameterValue="$customer_c_private_subnet" \
         ParameterKey=ServiceName,ParameterValue="$Vpce_Service_Name" > /dev/null
fi


#
# Now deploy Linux Instance in Customer VPC A
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3a" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack3a" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_WebLinuxInstances.yaml \
        --parameters    ParameterKey=VPCID,ParameterValue="$CA_VPC" \
                        ParameterKey=KeyPair,ParameterValue="$key" \
                        ParameterKey=InstanceType,ParameterValue="$linux_instance_type" \
                        ParameterKey=HealthCheckPort,ParameterValue="$linux_health_check_port" \
                        ParameterKey=CustomerSubnet,ParameterValue="$CA_Private_SUBNET" \
                        ParameterKey=CIDRForInstanceAccess,ParameterValue="$access_private" > /dev/null
fi


#
# Now deploy Linux Instance in Customer VPC B
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3b" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack3b" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_WebLinuxInstances.yaml \
        --parameters    ParameterKey=VPCID,ParameterValue="$CB_VPC" \
                        ParameterKey=KeyPair,ParameterValue="$key" \
                        ParameterKey=InstanceType,ParameterValue="$linux_instance_type" \
                        ParameterKey=HealthCheckPort,ParameterValue="$linux_health_check_port" \
                        ParameterKey=CustomerSubnet,ParameterValue="$CB_Private_SUBNET" \
                        ParameterKey=CIDRForInstanceAccess,ParameterValue="$access_private" > /dev/null
fi


#
# Now deploy Linux Instance in Customer VPC C
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3c" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack3c" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_WebLinuxInstances.yaml \
        --parameters    ParameterKey=VPCID,ParameterValue="$CC_VPC" \
                        ParameterKey=KeyPair,ParameterValue="$key" \
                        ParameterKey=InstanceType,ParameterValue="$linux_instance_type" \
                        ParameterKey=HealthCheckPort,ParameterValue="$linux_health_check_port" \
                        ParameterKey=CustomerSubnet,ParameterValue="$CC_Private_SUBNET" \
                        ParameterKey=CIDRForInstanceAccess,ParameterValue="$access_private" > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3a1" |wc -l`
    if [ "${count}" -ne "0" ]
    then
        break
    fi
    sleep $pause
done


#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3b1" |wc -l`
    if [ "${count}" -ne "0" ]
    then
        break
    fi
    sleep $pause
done


#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3c1" |wc -l`
    if [ "${count}" -ne "0" ]
    then
        break
    fi
    sleep $pause
done

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3a" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3b" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3c" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack1.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack3a1" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
CA_Vpce_Endpoint_Id=`cat $tfile|grep ^ScApplianceVpcEndpointId|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Created Customer A VPC Endpoint = $CA_Vpce_Endpoint_Id"
echo


#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack1.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack3b1" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
CB_Vpce_Endpoint_Id=`cat $tfile|grep ^ScApplianceVpcEndpointId|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Created Customer B VPC Endpoint = $CB_Vpce_Endpoint_Id"
echo

#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack1.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack3c1" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
CC_Vpce_Endpoint_Id=`cat $tfile|grep ^ScApplianceVpcEndpointId|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Created Customer C VPC Endpoint = $CC_Vpce_Endpoint_Id"
echo


#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack2.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack3a" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
CA_Linux_ID=`cat $tfile|grep ^WebLinuxInstanceID|cut -f2 -d$'\t'`
CA_Linux_IP=`cat $tfile|grep ^WebLinuxInstanceIP|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Customer A Linux Instance ID = $CA_Linux_ID"
echo "Customer A Linux IP = $CA_Linux_IP"
echo


#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack2.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack3b" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
CB_Linux_ID=`cat $tfile|grep ^WebLinuxInstanceID|cut -f2 -d$'\t'`
CB_Linux_IP=`cat $tfile|grep ^WebLinuxInstanceIP|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Customer B Linux Instance ID = $CB_Linux_ID"
echo "Customer B Linux IP = $CB_Linux_IP"
echo


#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack2.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack3c" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
CC_Linux_ID=`cat $tfile|grep ^WebLinuxInstanceID|cut -f2 -d$'\t'`
CC_Linux_IP=`cat $tfile|grep ^WebLinuxInstanceIP|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Customer C Linux Instance ID = $CC_Linux_ID"
echo "Customer C Linux IP = $CC_Linux_IP"
echo

exit
#
# End of the script
#

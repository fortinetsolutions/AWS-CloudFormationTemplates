#!/usr/bin/env bash

source $(dirname $0)/stack_parameters_option2.sh

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
        --template-body file://BaseVPC_Dual_AZ_option2.yaml \
        --parameters ParameterKey=VPCCIDR,ParameterValue="$ha_cidr" \
         ParameterKey=AZForSubnet1,ParameterValue="$region"a \
         ParameterKey=AZForSubnet2,ParameterValue="$region"c \
         ParameterKey=PublicSubnet1,ParameterValue="$ha_public1_subnet" \
         ParameterKey=PrivateSubnet1,ParameterValue="$ha_private1_subnet" \
         ParameterKey=TGWSubnet1,ParameterValue="$ha_tgw1_subnet" \
         ParameterKey=VPCeSubnet1,ParameterValue="$ha_vpce1_subnet" \
         ParameterKey=TGWSubnet2,ParameterValue="$ha_tgw2_subnet" \
         ParameterKey=VPCeSubnet2,ParameterValue="$ha_vpce2_subnet" \
         ParameterKey=PublicSubnet2,ParameterValue="$ha_public2_subnet" \
         ParameterKey=PrivateSubnet2,ParameterValue="$ha_private2_subnet" > /dev/null
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
TGW1_SUBNET=`cat $tfile|grep ^TGW1ID|cut -f2 -d$'\t'`
VPCe1_SUBNET=`cat $tfile|grep ^VPCe1ID|cut -f2 -d$'\t'`
Public2_SUBNET=`cat $tfile|grep ^Public2ID|cut -f2 -d$'\t'`
Private2_SUBNET=`cat $tfile|grep ^Private2ID|cut -f2 -d$'\t'`
TGW2_SUBNET=`cat $tfile|grep ^TGW2ID|cut -f2 -d$'\t'`
VPCe2_SUBNET=`cat $tfile|grep ^VPCe2ID|cut -f2 -d$'\t'`
Public1RouteTableID=`cat $tfile|grep ^Public1RouteTableID|cut -f2 -d$'\t'`
Public2RouteTableID=`cat $tfile|grep ^Public2RouteTableID|cut -f2 -d$'\t'`
PrivateRouteTable1ID=`cat $tfile|grep ^PrivateRouteTable1ID|cut -f2 -d$'\t'`
TGWRouteTable1ID=`cat $tfile|grep ^TGWRouteTable1ID|cut -f2 -d$'\t'`
VPCeRouteTable1ID=`cat $tfile|grep ^VPCeRouteTable1ID|cut -f2 -d$'\t'`
NatGateway1ID=`cat $tfile|grep ^NatGateway1ID|cut -f2 -d$'\t'`
PrivateRouteTable2ID=`cat $tfile|grep ^PrivateRouteTable2ID|cut -f2 -d$'\t'`
TGWRouteTable2ID=`cat $tfile|grep ^TGWRouteTable2ID|cut -f2 -d$'\t'`
VPCeRouteTable2ID=`cat $tfile|grep ^VPCeRouteTable2ID|cut -f2 -d$'\t'`
NatGateway2ID=`cat $tfile|grep ^NatGateway2ID|cut -f2 -d$'\t'`
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
echo "TGW Subnet 1 = $TGW1_SUBNET"
echo "VPCe Subnet 1 = $VPCe1_SUBNET"
echo "Public Subnet 2 = $Public2_SUBNET"
echo "Private Subnet 2 = $Private2_SUBNET"
echo "TGW Subnet 2 = $TGW2_SUBNET"
echo "VPCe Subnet 2 = $VPCe2_SUBNET"
echo "Public 1 Route Table ID = $Public1RouteTableID"
echo "Public 2 Route Table ID = $Public2RouteTableID"
echo "Private Route Table 1 ID = $PrivateRouteTable1ID"
echo "TGW Route Table 1 ID = $TGWRouteTable1ID"
echo "VPCe Route Table 1 ID = $VPCeRouteTable1ID"
echo "NAT Gateway 1 ID = $NatGateway1ID"
echo "Private Route Table  2 ID = $PrivateRouteTable2ID"
echo "TGW Route Table 2 ID = $TGWRouteTable2ID"
echo "VPCe Route Table 2 ID = $VPCeRouteTable2ID"
echo "NAT Gateway 2 ID = $NatGateway2ID"
echo

nat_info_line=$(aws ec2 describe-network-interfaces --region "$region" --filter "Name=subnet-id,Values=$Public1_SUBNET" --output text \
    --query 'NetworkInterfaces[?contains(Description, `Interface for NAT Gateway`) == `true`].[PrivateIpAddress,NetworkInterfaceId,Description]')
nat_ip_address1=`echo $nat_info_line | cut -d ' ' -f1`
if [[ $nat_ip_address1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
    echo "NAT Gateway IP Address in AZ 1 = $nat_ip_address1"
else
    echo "NAT Gateway does not have a valid IP address: $nat_ip_address1"
    exit
fi
nat_info_line=$(aws ec2 describe-network-interfaces --region "$region" --filter "Name=subnet-id,Values=$Public2_SUBNET" --output text \
    --query 'NetworkInterfaces[?contains(Description, `Interface for NAT Gateway`) == `true`].[PrivateIpAddress,NetworkInterfaceId,Description]')
nat_ip_address2=`echo $nat_info_line | cut -d ' ' -f1`
if [[ $nat_ip_address2 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
    echo "NAT Gateway IP Address in AZ 2 = $nat_ip_address2"
    echo
else
    echo "NAT Gateway does not have a valid IP address: $nat_ip_address2"
    echo
    exit
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
    read -n1 -r -p "Press enter to Deploy Transit Gateway and attach to Security VPC and deploy GWLB..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

#
# Deploy the Transit Gateway and Attach to the Security VPC
# Deploy Security VPC GWLB (GWLB_ExistingVPC.yaml)
#
if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack1t" Template and the script will pause when the create-stack is complete"
    echo "Deploying "$stack2b" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack1t" Template"
    echo "Deploying "$stack2b" Template"
fi


#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1t" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack1t" --output text --region "$region" \
        --template-body file://AWS_TransitGateway.yaml \
        --parameters ParameterKey=VpcId,ParameterValue="$VPC" \
         ParameterKey=AmazonSideAsn,ParameterValue="64512" \
         ParameterKey=TgwSubnets,ParameterValue=\"$TGW1_SUBNET,$TGW2_SUBNET\" \
         ParameterKey=TgwDescription,ParameterValue="tgw_name" \
         ParameterKey=AutoAcceptSharedAttachments,ParameterValue="disable" \
         ParameterKey=DefaultRouteTableAssociation,ParameterValue="disable" \
         ParameterKey=DefaultRouteTablePropagation,ParameterValue="disable" \
         ParameterKey=DnsSupport,ParameterValue="disable" \
         ParameterKey=MulticastSupport,ParameterValue="disable" \
         ParameterKey=VpnEcmpSupport,ParameterValue="enable" > /dev/null
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
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1t" |wc -l`
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
tfile=$(mktemp /tmp/foostack1.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack1t" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
TGW_ID=`cat $tfile|grep ^TransitGatewayId|cut -f2 -d$'\t'`
TransitGatewaySecurityRouteTableId=`cat $tfile|grep ^TransitGatewaySecurityRouteTableId|cut -f2 -d$'\t'`
TransitGatewaySecurityAttachmentId=`cat $tfile|grep ^TransitGatewaySecurityAttachmentId|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Transit Gateway ID = $TGW_ID"
echo "Transit Gateway Security Route Table ID = $TransitGatewaySecurityRouteTableId"
echo "Transit Gateway Security Attachment ID = $TransitGatewaySecurityAttachmentId"
echo


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
echo "Gateway Load Balancer ARN = $GWLB_ARN"
echo

lb_info_line=$(aws ec2 describe-network-interfaces --region "$region" --filter "Name=subnet-id,Values=$Private1_SUBNET" --output text \
    --query 'NetworkInterfaces[?contains(Description, `-gateway-lb`) == `true`].[PrivateIpAddress,NetworkInterfaceId,Description]')
lb_ip_address1=`echo $lb_info_line | cut -d ' ' -f1`
if [[ $lb_ip_address1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
    echo "Load Balancer IP Address in AZ 1 = $lb_ip_address1"
else
    echo "Load Balancer does not have a valid IP address: $lb_ip_address1"
    exit
fi

lb_info_line=$(aws ec2 describe-network-interfaces --region "$region" --filter "Name=subnet-id,Values=$Private2_SUBNET" --output text \
    --query 'NetworkInterfaces[?contains(Description, `-gateway-lb`) == `true`].[PrivateIpAddress,NetworkInterfaceId,Description]')
lb_ip_address2=`echo $lb_info_line | cut -d ' ' -f1`
if [[ $lb_ip_address2 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
    echo "Load Balancer IP Address in AZ 2 = $lb_ip_address2"
    echo
else
    echo "Load Balancer does not have a valid IP address: $lb_ip_address2"
    echo
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
    read -n1 -r -p "Press enter to deploy Fortigate Instances into existing Security VPC..." keypress
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
# Now deploy fortigate instances in the public & private subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2a" |wc -l`
if [ "${count}" -eq "0" ]
then
    #
    # Recalculate the Fortigate 1 and 2 Public IP addresses, if they conflict with the NAT Gateway IP address
    #
    host_ip=`echo "$fortigate1_public_ip"|cut -f1 -d"/"`
    subnet_bits=`echo "$fortigate1_public_ip"|cut -f2 -d"/"`
    if [ "$host_ip" == "$nat_ip_address1" ]
    then
        echo "Host IP Conflict ($host_ip) with NAT Gateway 1 IP address ($nat_ip_address1)"
        net="$(echo $host_ip |cut -d. -f1-3)"
        host="$(echo $host_ip | cut -d. -f4)"
        host=$(( $host +1))
        fortigate1_public_ip="$(echo $net.$host/$subnet_bits)"
        echo "Changing Fortigate 1 Public IP to $fortigate1_public_ip"
    else
        echo "No NAT Gateway IP conflict in Public 1 Subnet"
    fi
    host_ip=`echo "$fortigate2_public_ip"|cut -f1 -d"/"`
    subnet_bits=`echo "$fortigate2_public_ip"|cut -f2 -d"/"`
    if [ "$host_ip" == "$nat_ip_address2" ]
    then
        echo "Host IP Conflict ($host_ip) with NAT Gateway 2 IP address ($nat_ip_address2)"
        net="$(echo $host_ip |cut -d. -f1-3)"
        host="$(echo $host_ip | cut -d. -f4)"
        host=$(( $host +1))
        fortigate2_public_ip="$(echo $net.$host/$subnet_bits)"
        echo "Changing Fortigate 2 Public IP to $fortigate2_public_ip"
    else
        echo "No NAT Gateway IP conflict in Public 2 Subnet"
    fi
    #
    # Recalculate the Fortigate 1 and 2 Private IP addresses, if they conflict with the GWLB IP address
    #
    host_ip=`echo "$fortigate1_private_ip"|cut -f1 -d"/"`
    subnet_bits=`echo "$fortigate1_private_ip"|cut -f2 -d"/"`
    if [ "$host_ip" == "$lb_ip_address1" ]
    then
        echo "Host IP Conflict ($host_ip) with LoadBalancer 1 IP address ($lb_ip_address1)"
        net="$(echo $host_ip |cut -d. -f1-3)"
        host="$(echo $host_ip | cut -d. -f4)"
        host=$(( $host +1))
        fortigate1_private_ip="$(echo $net.$host/28)"
        echo "Changing Fortigate 1 Private IP to $fortigate1_private_ip"
    else
        echo "No Load Balancer IP conflict in Private 1 Subnet"
    fi
    host_ip=`echo "$fortigate2_private_ip"|cut -f1 -d"/"`
    subnet_bits=`echo "$fortigate2_private_ip"|cut -f2 -d"/"`
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
        --template-body file://Fortigate_ExistingVPC_option2.yaml \
        --parameters    ParameterKey=VPCID,ParameterValue="$VPC" \
                        ParameterKey=VPCCIDR,ParameterValue="$VPCCIDR" \
                        ParameterKey=Public1RouteTableID,ParameterValue="$Public1RouteTableID" \
                        ParameterKey=Public2RouteTableID,ParameterValue="$Public2RouteTableID" \
                        ParameterKey=Public1Subnet,ParameterValue="$Public1_SUBNET" \
                        ParameterKey=Private1Subnet,ParameterValue="$Private1_SUBNET" \
                        ParameterKey=Public2Subnet,ParameterValue="$Public2_SUBNET" \
                        ParameterKey=Private2Subnet,ParameterValue="$Private2_SUBNET" \
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
                        ParameterKey=Private1CIDR,ParameterValue="$ha_private1_subnet" \
                        ParameterKey=Private2CIDR,ParameterValue="$ha_private2_subnet" \
                        ParameterKey=Public1SubnetRouterIP,ParameterValue="$public1_subnet_router" \
                        ParameterKey=Public2SubnetRouterIP,ParameterValue="$public2_subnet_router" \
                        ParameterKey=Private1SubnetRouterIP,ParameterValue="$private1_subnet_router" \
                        ParameterKey=Private2SubnetRouterIP,ParameterValue="$private2_subnet_router" \
                        ParameterKey=LoadBalancerIP1,ParameterValue="$lb_ip_address1" \
                        ParameterKey=LoadBalancerIP2,ParameterValue="$lb_ip_address2" \
                        ParameterKey=FortiGate1PublicIP,ParameterValue="$fortigate1_public_ip" \
                        ParameterKey=FortiGate1PrivateIP,ParameterValue="$fortigate1_private_ip" \
                        ParameterKey=FortiGate2PublicIP,ParameterValue="$fortigate2_public_ip" \
                        ParameterKey=FortiGate2PrivateIP,ParameterValue="$fortigate2_private_ip" > /dev/null
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
echo "Changing Default Route (0.0.0.0/0) of Private Route Table 2 $PrivateRouteTable2ID to use ENI of Fortigate 2 ($Fortigate2PrivateENI)"
aws ec2 replace-route --region "$region" --route-table-id "$PrivateRouteTable2ID" --destination-cidr-block 0.0.0.0/0 --network-interface-id "$Fortigate2PrivateENI"
echo

#
# Deploy Security VPC Gateway LoadBalancer Target Group (Gwlb_Tg_Existing.yaml)
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
# Now deploy an GWLB Target Group pointing to the IP Address of the Existing Fortigate's
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
# DEPLOY A VPC Endpoint in AZ 1 and AZ 2
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
    read -n1 -r -p "Press enter to deploy vpc endpoint in AZ1 and AZ2 ..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack2e" Template and the script will pause when the create-stack is complete"
    echo "Deploying "$stack2f" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack2e" Template"
    echo "Deploying "$stack2f" Template"
fi


#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2e" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack2e" --output text --region "$region" \
        --template-body file://AWS_VPC_Endpoint_Existing_option2.yaml \
        --parameters ParameterKey=VpcId,ParameterValue="$VPC" \
         ParameterKey=VpceSubnetId,ParameterValue="$VPCe1_SUBNET" \
         ParameterKey=TgwRouteTableId,ParameterValue="$TGWRouteTable1ID" \
         ParameterKey=ServiceName,ParameterValue="$Vpce_Service_Name" > /dev/null
fi


#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2f" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack2f" --output text --region "$region" \
        --template-body file://AWS_VPC_Endpoint_Existing_option2.yaml \
        --parameters ParameterKey=VpcId,ParameterValue="$VPC" \
         ParameterKey=VpceSubnetId,ParameterValue="$VPCe2_SUBNET" \
         ParameterKey=TgwRouteTableId,ParameterValue="$TGWRouteTable2ID" \
         ParameterKey=ServiceName,ParameterValue="$Vpce_Service_Name" > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#1
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2e" |wc -l`
    if [ "${count}" -ne "0" ]
    then
        break
    fi
    sleep $pause
done


#
# Wait for template above to CREATE_COMPLETE
#1
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2f" |wc -l`
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
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack2e" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
Vpce_Endpoint1_Id=`cat $tfile|grep ^ScApplianceVpcEndpointId|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Created VPC Endpoint = $Vpce_Endpoint1_Id"
echo


#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack1.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack2f" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
Vpce_Endpoint2_Id=`cat $tfile|grep ^ScApplianceVpcEndpointId|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Created VPC Endpoint = $Vpce_Endpoint2_Id"
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
    read -n1 -r -p "Press enter to deploy customer A vpc..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack1a" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack1a" Template"
fi


#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1a" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack1a" --output text --region "$region" \
        --template-body file://BaseVPC_Customer_option2.yaml \
        --parameters ParameterKey=VPCCIDR,ParameterValue="$customer_a_cidr" \
         ParameterKey=PublicSubnet,ParameterValue="$customer_a_public_subnet" \
         ParameterKey=Public1RouteTableId,ParameterValue="$Public1RouteTableID" \
         ParameterKey=Public2RouteTableId,ParameterValue="$Public2RouteTableID" \
         ParameterKey=VPCe1RouteTableId,ParameterValue="$VPCeRouteTable1ID" \
         ParameterKey=VPCe2RouteTableId,ParameterValue="$VPCeRouteTable2ID" \
         ParameterKey=VPCe1Id,ParameterValue="$Vpce_Endpoint1_Id" \
         ParameterKey=VPCe2Id,ParameterValue="$Vpce_Endpoint2_Id" \
         ParameterKey=TgwSecurityRouteTableId,ParameterValue="$TransitGatewaySecurityRouteTableId" \
         ParameterKey=TgwId,ParameterValue="$TGW_ID" \
         ParameterKey=TgwSecurityAttachmentId,ParameterValue="$TransitGatewaySecurityAttachmentId" \
         ParameterKey=AZ,ParameterValue="$customer_a_az" > /dev/null
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
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack1.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack1a" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
CA_VPC=`cat $tfile|grep ^VPCID|cut -f2 -d$'\t'`
CA_VPCCIDR=`cat $tfile|grep ^VPCCIDR|cut -f2 -d$'\t'`
CA_AZ=`cat $tfile|grep ^AZ|cut -f2 -d$'\t'`
CA_Public_SUBNET=`cat $tfile|grep ^PublicID|cut -f2 -d$'\t'`
CA_PublicRouteTableID=`cat $tfile|grep ^PublicRouteTableID|cut -f2 -d$'\t'`
CA_Extra_SUBNET=`cat $tfile|grep ^ExtraID|cut -f2 -d$'\t'`
CA_ExtraRouteTableID=`cat $tfile|grep ^ExtraRouteTableID|cut -f2 -d$'\t'`
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
echo "Extra Subnet = $CA_Extra_SUBNET"
echo "Extra Route Table ID = $CA_ExtraRouteTableID"
echo

#
#Deploy Customer A VPC Linux Endpoint
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
    read -n1 -r -p "Press enter to deploy Customer A Linux Endpoints and Extra Endpoints ..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done


if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack3a" Template and the script will pause when the create-stack is complete"
    echo "Deploying "$stack3e" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack3a" Template"
    echo "Deploying "$stack3e" Template"
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
                        ParameterKey=CustomerSubnet,ParameterValue="$CA_Public_SUBNET" \
                        ParameterKey=CIDRForInstanceAccess,ParameterValue="$access_private" > /dev/null
fi


#
# Now deploy Linux Instance in Customer VPC A
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3e" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack3e" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://ExistingVPC_WebLinuxInstances.yaml \
        --parameters    ParameterKey=VPCID,ParameterValue="$CA_VPC" \
                        ParameterKey=KeyPair,ParameterValue="$key" \
                        ParameterKey=InstanceType,ParameterValue="$linux_instance_type" \
                        ParameterKey=HealthCheckPort,ParameterValue="$linux_health_check_port" \
                        ParameterKey=CustomerSubnet,ParameterValue="$CA_Extra_SUBNET" \
                        ParameterKey=CIDRForInstanceAccess,ParameterValue="$access_private" > /dev/null
fi

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
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3e" |wc -l`
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
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack3a" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
CA_Linux_ID=`cat $tfile|grep ^WebLinuxInstanceID|cut -f2 -d$'\t'`
CA_Linux_IP=`cat $tfile|grep ^WebLinuxInstanceIP|cut -f2 -d$'\t'`
CA_Linux_Private_IP=`cat $tfile|grep ^WebLinuxInstancePrivateIP|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Customer A Linux Instance ID = $CA_Linux_ID"
echo "Customer A Linux IP = $CA_Linux_IP"
echo "Customer A Linux Private IP = $CA_Linux_Private_IP"
echo


#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack2.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack3e" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
CA_Linux_Extra_ID=`cat $tfile|grep ^WebLinuxInstanceID|cut -f2 -d$'\t'`
CA_Linux_Extra_IP=`cat $tfile|grep ^WebLinuxInstanceIP|cut -f2 -d$'\t'`
CA_Linux_Extra_Private_IP=`cat $tfile|grep ^WebLinuxInstancePrivateIP|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Customer A Extra Linux Instance ID = $CA_Linux_Extra_ID"
echo "Customer A Extra Linux IP = $CA_Linux_Extra_IP"
echo "Customer A Linux Extra Private IP = $CA_Linux_Extra_Private_IP"
echo

exit
#
# End of the script
#

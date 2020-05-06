#!/usr/bin/env bash

source $(dirname $0)/stack_parameters.sh

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
        --template-body file://BaseVPC_FGCP_DualAZ.template.yaml \
        --parameters ParameterKey=VPCCIDR,ParameterValue="$ha_cidr" \
         ParameterKey=PublicSubnet2,ParameterValue="$ha_public_subnet2" \
         ParameterKey=PublicSubnet1,ParameterValue="$ha_public_subnet1" \
         ParameterKey=MiddleSubnet2,ParameterValue="$ha_middle_subnet2" \
         ParameterKey=MiddleSubnet1,ParameterValue="$ha_middle_subnet1" \
         ParameterKey=PrivateSubnet2,ParameterValue="$ha_private_subnet2" \
         ParameterKey=PrivateSubnet1,ParameterValue="$ha_private_subnet1" \
         ParameterKey=HASyncSubnet2,ParameterValue="$ha_sync_subnet2" \
         ParameterKey=HASyncSubnet1,ParameterValue="$ha_sync_subnet1" \
         ParameterKey=HAMgmtSubnet2,ParameterValue="$ha_mgmt_subnet2" \
         ParameterKey=HAMgmtSubnet1,ParameterValue="$ha_mgmt_subnet1" \
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
Private_SUBNET1=`cat $tfile|grep ^PrivateID1|cut -f2 -d$'\t'`
Private_SUBNET2=`cat $tfile|grep ^PrivateID2|cut -f2 -d$'\t'`
Public_SUBNET1=`cat $tfile|grep ^PublicID1|cut -f2 -d$'\t'`
Public_SUBNET2=`cat $tfile|grep ^PublicID2|cut -f2 -d$'\t'`
Middle_SUBNET1=`cat $tfile|grep ^MiddleID1|cut -f2 -d$'\t'`
Middle_SUBNET2=`cat $tfile|grep ^MiddleID2|cut -f2 -d$'\t'`
HAMgmt_SUBNET1=`cat $tfile|grep ^HAMgmtID1|cut -f2 -d$'\t'`
HAMgmt_SUBNET2=`cat $tfile|grep ^HAMgmtID2|cut -f2 -d$'\t'`
HASync_SUBNET1=`cat $tfile|grep ^HASyncID1|cut -f2 -d$'\t'`
HASync_SUBNET2=`cat $tfile|grep ^HASyncID2|cut -f2 -d$'\t'`
Public_RouteTableID=`cat $tfile|grep ^PublicRouteTableID|cut -f2 -d$'\t'`
Middle_RouteTableID=`cat $tfile|grep ^MiddleRouteTableID|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Created VPC = $VPC"
echo "VPC Cidr Block = $VPCCIDR"
echo "Availability Zone 1 = $AZ1"
echo "Availability Zone 2 = $AZ2"
echo "Public Subnet 1 = $Public_SUBNET1"
echo "Public Subnet 2 = $Public_SUBNET2"
echo "Middle Subnet 1 = $Middle_SUBNET1"
echo "Middle Subnet 2 = $Middle_SUBNET2"
echo "Private Subnet 1 = $Private_SUBNET1"
echo "Private Subnet 2 = $Private_SUBNET2"
echo "Sync Subnet 1 = $HASync_SUBNET1"
echo "Sync Subnet 2 = $HASync_SUBNET2"
echo "Management Subnet 1 = $HAMgmt_SUBNET1"
echo "Management Subnet 2 = $HAMgmt_SUBNET2"
echo "Public Route Table ID = $Public_RouteTableID"
echo "Middle Route Table ID = $Middle_RouteTableID"
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
    read -n1 -r -p "Press enter to deploy public high availability group..." keypress
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
# Now deploy fortigate HA instances in the public & private subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack2" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://FGCP_DualAZ_ExistingVPC.template.yaml \
        --parameters    ParameterKey=VPCID,ParameterValue="$VPC" \
                        ParameterKey=VPCCIDR,ParameterValue="$VPCCIDR" \
                        ParameterKey=PublicSubnet1,ParameterValue="$Public_SUBNET1" \
                        ParameterKey=PrivateSubnet1,ParameterValue="$Middle_SUBNET1" \
                        ParameterKey=HASyncSubnet1,ParameterValue="$HASync_SUBNET1" \
                        ParameterKey=HAMgmtSubnet1,ParameterValue="$HAMgmt_SUBNET1" \
                        ParameterKey=PublicSubnet2,ParameterValue="$Public_SUBNET2" \
                        ParameterKey=PrivateSubnet2,ParameterValue="$Middle_SUBNET2" \
                        ParameterKey=HASyncSubnet2,ParameterValue="$HASync_SUBNET2" \
                        ParameterKey=HAMgmtSubnet2,ParameterValue="$HAMgmt_SUBNET2" \
                        ParameterKey=InstanceType,ParameterValue="$fgt_instance_type" \
                        ParameterKey=CIDRForInstanceAccess,ParameterValue="$access_public" \
                        ParameterKey=AZForFGT1,ParameterValue="$AZ1" \
                        ParameterKey=AZForFGT2,ParameterValue="$AZ2" \
                        ParameterKey=KeyPair,ParameterValue="$key" \
                        ParameterKey=InitS3Bucket,ParameterValue="$license_bucket" \
                        ParameterKey=InitS3BucketRegion,ParameterValue="$region" \
                        ParameterKey=LicenseType,ParameterValue="$license_type" \
                        ParameterKey=FortiGate1LicenseFile,ParameterValue="$fortigate1_license_file" \
                        ParameterKey=FortiGate2LicenseFile,ParameterValue="$fortigate2_license_file" \
                        ParameterKey=PublicSubnet1RouterIP,ParameterValue="$public_subnet1_router" \
                        ParameterKey=PrivateSubnet1RouterIP,ParameterValue="$middle_subnet1_router" \
                        ParameterKey=HAMgmtSubnet1RouterIP,ParameterValue="$hamgmt_subnet1_router" \
                        ParameterKey=PublicSubnet2RouterIP,ParameterValue="$public_subnet2_router" \
                        ParameterKey=PrivateSubnet2RouterIP,ParameterValue="$middle_subnet2_router" \
                        ParameterKey=HAMgmtSubnet2RouterIP,ParameterValue="$hamgmt_subnet2_router" \
                        ParameterKey=FortiGate1PublicIP,ParameterValue="$fortigate1_public_ip" \
                        ParameterKey=FortiGate1PrivateIP,ParameterValue="$fortigate1_middle_ip" \
                        ParameterKey=FortiGate1HAsyncIP,ParameterValue="$fortigate1_sync_ip" \
                        ParameterKey=FortiGate1HAmgmtIP,ParameterValue="$fortigate1_mgmt_ip" \
                        ParameterKey=FortiGate2PublicIP,ParameterValue="$fortigate2_public_ip" \
                        ParameterKey=FortiGate2PrivateIP,ParameterValue="$fortigate2_middle_ip" \
                        ParameterKey=FortiGate2HAsyncIP,ParameterValue="$fortigate2_sync_ip" \
                        ParameterKey=FortiGate2HAmgmtIP,ParameterValue="$fortigate2_mgmt_ip" > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2" |wc -l`
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
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack2" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
CLUSTER_URL=`cat $tfile|grep ^ClusterLoginURL|cut -f2 -d$'\t'`
Fortigate1_Login_URL=`cat $tfile|grep ^FortiGate1LoginURL|cut -f2 -d$'\t'`
Fortigate2_Login_URL=`cat $tfile|grep ^FortiGate2LoginURL|cut -f2 -d$'\t'`
Fortigate1ENI=`cat $tfile|grep ^FortiGate1ENI|cut -f2 -d$'\t'`
Fortigate2ENI=`cat $tfile|grep ^FortiGate2ENI|cut -f2 -d$'\t'`
Fortigate_Password=`cat $tfile|grep ^Password|cut -f2 -d$'\t'`
Fortigate_Username=`cat $tfile|grep ^Username|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Cluster Login URL = $CLUSTER_URL"
echo "Fortigate 1 Login URL = $Fortigate1_Login_URL"
echo "Fortigate 2 Login URL = $Fortigate2_Login_URL"
echo "Fortigate 1 ENI ID = $Fortigate1ENI"
echo "Fortigate 2 ENI ID = $Fortigate2ENI"
echo "Fortigate Password = $Fortigate_Password"
echo "Fortigate Username = $Fortigate_Username"
echo

aws ec2 create-route --route-table-id "$Middle_RouteTableID" --destination-cidr-block 0.0.0.0/0 --network-interface-id "$Fortigate1ENI"

if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
while [ $keypress_loop == true ]
do
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy private high availability group..." keypress
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
# Now deploy fortigate HA instances in the public & private subnets on top of the existing VPC
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack3" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack3" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://FGCP_DualAZ_ExistingVPC_Private.template.yaml \
        --parameters    ParameterKey=VPCID,ParameterValue="$VPC" \
                        ParameterKey=VPCCIDR,ParameterValue="$VPCCIDR" \
                        ParameterKey=PublicSubnet1,ParameterValue="$Middle_SUBNET1" \
                        ParameterKey=PrivateSubnet1,ParameterValue="$Private_SUBNET1" \
                        ParameterKey=HASyncSubnet1,ParameterValue="$HASync_SUBNET1" \
                        ParameterKey=HAMgmtSubnet1,ParameterValue="$HAMgmt_SUBNET1" \
                        ParameterKey=PublicSubnet2,ParameterValue="$Middle_SUBNET2" \
                        ParameterKey=PrivateSubnet2,ParameterValue="$Private_SUBNET2" \
                        ParameterKey=HASyncSubnet2,ParameterValue="$HASync_SUBNET2" \
                        ParameterKey=HAMgmtSubnet2,ParameterValue="$HAMgmt_SUBNET2" \
                        ParameterKey=InstanceType,ParameterValue="$fgt_instance_type" \
                        ParameterKey=CIDRForInstanceAccess,ParameterValue="$access_private" \
                        ParameterKey=AZForFGT1,ParameterValue="$AZ1" \
                        ParameterKey=AZForFGT2,ParameterValue="$AZ2" \
                        ParameterKey=KeyPair,ParameterValue="$key" \
                        ParameterKey=InitS3Bucket,ParameterValue="$license_bucket2" \
                        ParameterKey=InitS3BucketRegion,ParameterValue="$region" \
                        ParameterKey=LicenseType,ParameterValue="PAYG" \
                        ParameterKey=FortiGate1LicenseFile,ParameterValue="" \
                        ParameterKey=FortiGate2LicenseFile,ParameterValue="" \
                        ParameterKey=PublicSubnet1RouterIP,ParameterValue="$middle_subnet1_router" \
                        ParameterKey=PrivateSubnet1RouterIP,ParameterValue="$private_subnet1_router" \
                        ParameterKey=HAMgmtSubnet1RouterIP,ParameterValue="$hamgmt_subnet1_router" \
                        ParameterKey=PublicSubnet2RouterIP,ParameterValue="$middle_subnet2_router" \
                        ParameterKey=PrivateSubnet2RouterIP,ParameterValue="$private_subnet2_router" \
                        ParameterKey=HAMgmtSubnet2RouterIP,ParameterValue="$hamgmt_subnet2_router" \
                        ParameterKey=FortiGate1PublicIP,ParameterValue="$fortigate3_middle_ip" \
                        ParameterKey=FortiGate1PrivateIP,ParameterValue="$fortigate3_private_ip" \
                        ParameterKey=FortiGate1HAsyncIP,ParameterValue="$fortigate3_sync_ip" \
                        ParameterKey=FortiGate1HAmgmtIP,ParameterValue="$fortigate3_mgmt_ip" \
                        ParameterKey=FortiGate2PublicIP,ParameterValue="$fortigate4_middle_ip" \
                        ParameterKey=FortiGate2PrivateIP,ParameterValue="$fortigate4_private_ip" \
                        ParameterKey=FortiGate2HAsyncIP,ParameterValue="$fortigate4_sync_ip" \
                        ParameterKey=FortiGate2HAmgmtIP,ParameterValue="$fortigate4_mgmt_ip" > /dev/null
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

#
# End of the script
#

#!/bin/bash
#
# Deploy the standalone template, wait for completion. Deploy Single Fortigate and modify route tables
# to push traffic through the Fortigate.
#
# Templates can be pulled from Fortiscripts repo: git clone git@bitbucket.org:fortiscripts/cloudformationtemplates.git
# Under StandAlone_Templates
#

URL=""

make_s3 ()
{
    if [ -z "$1" ]
    then
        echo "No bucket specified"
        return -1
    fi
    if [ -z "$2" ]
    then
        echo "No template specified"
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

deploy_first_stack ()
{
    U="$1"
    NAME="$2"
    CNT="$3"
    if [ -z "$1" ]
    then
        echo "No URL name specified"
        return -1
    fi
    if [ -z "$2" ]
    then
        echo "No stack name specified"
        return -1
    fi
    if [ -z "$3" ]
    then
        echo "No count specified"
        CNT=1
    fi
    #
    # Create the stack with all the parameters
    #
    STACK_NAME=$NAME-$CNT-1
    aws cloudformation create-stack --stack-name "$STACK_NAME" \
    --template-url $U \
    --parameters ParameterKey=Private1Subnet,ParameterValue="10.$CNT.1.0/24" \
    ParameterKey=Public1Subnet,ParameterValue=10.$CNT.0.0/24 \
    ParameterKey=VPCCIDR,ParameterValue="10.$CNT.0.0/16" \
    ParameterKey=AZForSubnet1,ParameterValue="us-east-1a"

    #
    # Wait for the stack deploy to complete
    #
    complete_stack=false
    while [ $complete_stack == false ]
    do
        status=`aws cloudformation describe-stacks --stack $NAME-$CNT-1 --query Stacks[0].StackStatus`
        if [ "$status" == '"CREATE_COMPLETE"' ]
        then
            complete_stack=true
        fi
        if [ $complete_stack == false ]
        then
            sleep 15
        fi
    done
}

deploy_second_stack ()
{
    U="$1"
    NAME="$2"
    CNT="$3"
    if [ -z "$1" ]
    then
        echo "No URL name specified"
        return -1
    fi
    if [ -z "$2" ]
    then
        echo "No stack name specified"
        return -1
    fi
    if [ -z "$3" ]
    then
        echo "No count specified"
        CNT=1
    fi
    STACK_NAME=$NAME-$CNT-2
    #
    # Get the values from the previous stack deploy for VPC ID, Public and Private subnets
    #
    VPC=`aws cloudformation list-stack-resources --stack-name $NAME-$CNT-1 --output text|grep VPCID |cut -f 4`
    S1=`aws cloudformation list-stack-resources --stack-name $NAME-$CNT-1 --output text|grep Subnet1 |cut -f 4`
    S2=`aws cloudformation list-stack-resources --stack-name $NAME-$CNT-1 --output text|grep Subnet2 |cut -f 4`

    #
    # Create the stack with all the parameters
    #
    aws cloudformation create-stack --stack-name "$STACK_NAME" \
    --template-url $U \
    --parameters ParameterKey=VPCID,ParameterValue="$VPC" \
    ParameterKey=Public1Subnet,ParameterValue="$S1" \
    ParameterKey=Private1Subnet,ParameterValue="$S2" \
    ParameterKey=FortiGateInstanceType,ParameterValue="m3.medium" \
    ParameterKey=CIDRForFortiGateAccess,ParameterValue="0.0.0.0/0"
    complete_stack=false
    #
    # Wait for stack deploy to complete
    #
    while [ $complete_stack == false ]
    do
        status=`aws cloudformation describe-stacks --stack $STACK_NAME --query Stacks[0].StackStatus`
        if [ "$status" == '"CREATE_COMPLETE"' ]
        then
            complete_stack=true
        fi
        if [ $complete_stack == false ]
        then
            sleep 15
        fi
    done

}

usage()
{
cat << EOF
usage: $0 options

This script runs aws cloudformation template deployment scripts

OPTIONS:
   -h   Show this message
   -c   Count
   -s   Stack Prefix
EOF
}

#
# Initialize these and force a command line to turn them on
#

while getopts hb:f:c:s:u: OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         c)
             COUNT=$OPTARG
             ;;
         s)
             STACK=$OPTARG
             ;;
         b)
             BUCKET=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

#
# Upload templates to S3
#
echo "Creating S3 bucket: $BUCKET and uploading file: NewVPC_BaseSetup_Single.template "
make_s3 $BUCKET NewVPC_BaseSetup_Single.template
if [ $? == -1 ]
then
    exit 10
fi
echo "Done!"
echo "Creating S3 bucket: $BUCKET and uploading file: ExistingVPC_Fortigate542_Single.template "
make_s3 $BUCKET ExistingVPC_Fortigate542_Single.template
if [ $? == -1 ]
then
    exit 10
fi
echo "Done!"

#
# Deploy the stacks multiple times based on COUNT
#
for c in `seq 1 $COUNT`
do
    FILE=NewVPC_BaseSetup_Single.template
    FURL="https://s3.amazonaws.com/$BUCKET/$FILE"
    echo "Creating stack: $STACK using $FURL with count = $c"
    #
    # Deploy the base stack containing subnets, route tables, route associations
    #
    deploy_first_stack $FURL $STACK $c
    echo "Done!"
    #
    # Fine the route table for the interal subnet. We need to modify the route table to point to
    # Fortigate internal interface, after it is created
    #
    RTB=`aws cloudformation list-stack-resources --stack-name $NAME-$CNT-1 --output text|grep RouteTable1 |cut -f 4`
    FILE=ExistingVPC_Fortigate542_Single.template
    FURL="https://s3.amazonaws.com/$BUCKET/$FILE"
    echo "Creating stack: $STACK using $FURL with count = $c"
    #
    # Now deploy a Fortigate into the stack above
    #
    deploy_second_stack $FURL $STACK $c
    #
    # Get the internal ENI of the Fortigate and replace the route table to make traffic go to Fortigate
    #
    ENI=`aws cloudformation list-stack-resources --stack-name $NAME-$CNT-2 --output text|grep OnDemandAENI1 |cut -f 4`
    aws ec2 replace-route --route-table-id $RTB --destination-cidr-block 0.0.0.0/0 --network-interface-id $ENI
done
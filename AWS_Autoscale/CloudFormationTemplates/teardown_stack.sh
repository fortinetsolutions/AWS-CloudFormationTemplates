#!/usr/bin/env bash

source $(dirname $0)/stack_parameters.sh

wait_for_zero_instances()
{
    if [ -z $1 ]
    then
        echo "wait_for_zero_instances(): $1 autoscale group name doesn't exist."
        return 0
    fi
    asg_name=$1
    zero_instances=false
    while [ "$zero_instances" == false ]
    do
        count=`aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[?contains(AutoScalingGroupName, '$asg_name')].{Name:InstanceId}"|wc -l`
        echo "Autoscale Group $i has $(($count)) instances"
        if [ $(($count)) == "0" ]
        then
            zero_instances=true
        else
            sleep 15
        fi
    done
}

delete_stack ()
{
    if [ -z $1 ]
    then
        echo "delete_stack(): $4 stack id doesn't exist. Skip teardown."
        return 0
    fi
    if [ -z $2 ]
    then
        echo "delete_stack(name): $4 stack name doesn't exist. Skip teardown."
        return 0
    fi
    if [ -z $3 ]
    then
        echo "delete_stack(name): $4 region stack doesn't exist. Skip teardown."
        return 0
    fi
    stack_name=$2
    tregion=$3
    if [ "$stack_name" != "" ] && [ "$tregion" != "" ]
    then
        aws cloudformation delete-stack --stack-name "$stack_name" --region "$region" > /dev/null
    fi
}

wait_for_stack_deletion ()
{
    if [ -z $1 ]
    then
        echo "wait_for_stack_delete stack_id zero length"
        return -1
    fi
    stack_id=$1
    if [ -z $2 ]
    then
        echo "wait_for_stack_delete stack_name zero length"
        return -1
    fi
    stack_name=$2
    if [ -z $3 ]
    then
        echo "wait_for_stack_delete region zero length"
        return -1
    fi
    region=$3

    delete_complete=false
    while [ "$delete_complete" == false ]
    do
        tfile=$(mktemp /tmp/foostack.XXXXXXXXX)
        aws cloudformation list-stacks  --region "$region" \
           --query "StackSummaries[?contains(StackId, '$stack_id')].{Name:StackName,Id:StackId,Status:StackStatus}" >$tfile
        tname=`cat $tfile |grep "$stack_name"|cut -f2 -d$'\t'`
        tarn=`cat $tfile |grep "$stack_name"|cut -f1 -d$'\t'`
        tstatus=`cat $tfile |grep "$stack_name"|cut -f3 -d$'\t'`
        if [ -f $tfile ]
        then
            rm -f $tfile
        fi
        if [ "$tname" == "$stack_name" ] && [ "$tarn" == "$stack_id" ] && [ "$tstatus" == "DELETE_COMPLETE" ]
        then
            delete_complete=true
        else
            sleep 15
        fi
    done
}

usage()
{
cat << EOF
usage: $0 options

This script will teardown the previously deploy stacks
EOF
}

while getopts kp:W OPTION
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
if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
tfile=$(mktemp /tmp/foostack.XXXXXXXXX)
aws cloudformation list-stack-resources --stack-name "$stack6" --region "$region" --query "StackResourceSummaries[?contains(ResourceType, 'AWS::AutoScaling::AutoScalingGroup')].{Name:PhysicalResourceId}" >$tfile
#
# break here
#
for i in `cat $tfile`
do
    echo "Updating Min and Desired to 0: Autoscale Group = $i"
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$i" --min-size 0 --desired-capacity 0
done
for i in `cat $tfile`
do
    echo "Waiting for zero instance in autoscale group $i"
    wait_for_zero_instances $i
done
if [ -f $tfile ]
then
    rm -f $tfile
fi
if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
tfile=$(mktemp /tmp/foostack.XXXXXXXXX)
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" \
    --query "StackSummaries[*].{name:StackName,id:StackId}" >$tfile
#
# break here
#
stack6_name=`cat $tfile |grep "$stack6"|cut -f2 -d$'\t'`
stack6_id=`cat $tfile |grep "$stack6"|cut -f1 -d$'\t'`
stack5_name=`cat $tfile |grep "$stack5"|cut -f2 -d$'\t'`
stack5_id=`cat $tfile |grep "$stack5"|cut -f1 -d$'\t'`
stack3_name=`cat $tfile |grep "$stack3"|cut -f2 -d$'\t'`
stack3_id=`cat $tfile |grep "$stack3"|cut -f1 -d$'\t'`
stack2_name=`cat $tfile |grep "$stack2"|cut -f2 -d$'\t'`
stack2_id=`cat $tfile |grep "$stack2"|cut -f1 -d$'\t'`
stack1_name=`cat $tfile |grep "$stack1"|cut -f2 -d$'\t'`
stack1_id=`cat $tfile |grep "$stack1"|cut -f1 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo "Stack 6 name $stack6_name id $stack6_id in region $region"
echo "Stack 5 name $stack5_name id $stack5_id in region $region"
echo "Stack 3 name $stack1_name id $stack3_id in region $region"
echo "Stack 2 name $stack1_name id $stack2_id in region $region"
echo "Stack 1 name $stack1_name id $stack1_id in region $region"
while [ $keypress_loop == true ]
do
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to cleanup stacks..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

if [ -n "$stack6_name" ]
then
    echo "Deleting $stack6_name id $stack6_id region $region"
    delete_stack $stack6_id $stack6_name $region $stack6
fi
if [ -n "$stack6_name" ]
then
    echo "Waiting for $stack6 deletion"
    wait_for_stack_deletion $stack6_id $stack6_name $region
fi
aws dynamodb list-tables | grep -v fortinet_autoscale | awk '{print $2}'|while read x; do echo "deleting table $x"; aws dynamodb delete-table --table-name $x; done
echo "Done"
if [ -n "$stack5_name" ]
then
    echo "Deleting $stack5_name id $stack5_id region $region"
    delete_stack $stack5_id $stack5_name $region $stack5
fi
if [ -n "$stack5_name" ]
then
    echo "Waiting for $stack5 deletion"
    wait_for_stack_deletion $stack5_id $stack5_name $region
fi
aws logs describe-log-groups --query 'logGroups[*].logGroupName' --output table --region $region | \
awk '{print $2}' | grep ^/aws/lambda | while read x; do  echo "deleting $x" ; aws logs delete-log-group --log-group-name $x; done
echo "Done"

#
# stack 3
#
if [ -n "$stack3_name" ]
then
    echo "Deleting $stack3_name id $stack3_id region $region"
    delete_stack $stack3_id $stack3_name $region $stack3
fi
if [ -n "$stack3_name" ]
then
    echo "Waiting for $stack3 deletion"
    wait_for_stack_deletion $stack3_id $stack3_name $region
fi
#
# stack 2
#
if [ -n "$stack2_name" ]
then
    echo "Deleting $stack2_name id $stack2_id region $region"
    delete_stack $stack2_id $stack2_name $region $stack2
fi
if [ -n "$stack2_name" ]
then
    echo "Waiting for $stack2 deletion"
    wait_for_stack_deletion $stack2_id $stack2_name $region
fi
#
# stack 1
#
if [ -n "$stack1_name" ]
then
    echo "Deleting $stack1_name id $stack1_id region $region"
    delete_stack $stack1_id $stack1_name $region $stack1
fi
if [ -n "$stack1_name" ]
then
    echo "Waiting for $stack1 deletion"
    wait_for_stack_deletion $stack1_id $stack1_name $region
fi

cd ../lambda_code/autoscale
rm -f autoscale-dev-*.zip
aws s3 rm s3://fortimdw-us-east-1/autoscale-dev.zip
zappa package dev
aws s3 cp autoscale-dev-*.zip s3://fortimdw-us-east-1/autoscale-dev.zip
cd -
aws dynamodb list-tables | awk '{print $2}'|while read x; do echo "deleting table $x"; aws dynamodb delete-table --table-name $x; done
echo "Done"


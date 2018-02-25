#!/usr/bin/env bash

source $(dirname $0)/stack_parameters.sh

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

#usage()
#{
#cat << EOF
#usage: $0 options
#
#This script will teardown the previously deploy stacks
#EOF
#}

#while getopts k OPTION
#do
#     case $OPTION in
#         ?)
#             usage
#             exit
#             ;;
#     esac
#done

tfile=$(mktemp /tmp/foostack.XXXXXXXXX)
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" \
    --query "StackSummaries[*].{name:StackName,id:StackId}" >$tfile
stack7_name=`cat $tfile |grep "$stack7"|cut -f2 -d$'\t'`
stack7_id=`cat $tfile |grep "$stack7"|cut -f1 -d$'\t'`
stack6_name=`cat $tfile |grep "$stack6"|cut -f2 -d$'\t'`
stack6_id=`cat $tfile |grep "$stack6"|cut -f1 -d$'\t'`
stack5_name=`cat $tfile |grep "$stack5"|cut -f2 -d$'\t'`
stack5_id=`cat $tfile |grep "$stack5"|cut -f1 -d$'\t'`
stack4_name=`cat $tfile |grep "$stack4"|cut -f2 -d$'\t'`
stack4_id=`cat $tfile |grep "$stack4"|cut -f1 -d$'\t'`
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

echo "Deleting $stack7_name id $stack7_id region $region"

delete_stack $stack7_id $stack7_name $region $stack7

echo "Deleting $stack6_name id $stack6_id region $region"

delete_stack $stack6_id $stack6_name $region $stack6

echo "Deleting bucket s3://$stack5-fortigate-configs"

aws s3 rb s3://$stack5-fortigate-configs --force

echo "Deleting $stack5_name id $stack5_id region $region"

delete_stack $stack5_id $stack5_name $region $stack5

echo "Waiting for $stack7 deletion"

wait_for_stack_deletion $stack7_id $stack7_name $region

echo "Waiting for $stack5 deletion"

wait_for_stack_deletion $stack6_id $stack6_name $region

echo "Waiting for $stack5 deletion"

wait_for_stack_deletion $stack5_id $stack5_name $region

echo "Deleting $stack4_name id $stack4_id region $region"

delete_stack $stack4_id $stack4_name $region $stack4

echo "Deleting $stack3_name id $stack3_id region $region"

delete_stack $stack3_id $stack3_name $region $stack3

echo "Deleting $stack2_name id $stack2_id region $region"

delete_stack $stack2_id $stack2_name $region $stack2

echo "Waiting for $stack4 deletion"

wait_for_stack_deletion $stack4_id $stack4_name $region

echo "Waiting for $stack3 deletion"

wait_for_stack_deletion $stack3_id $stack3_name $region

echo "Waiting for $stack2 deletion"

wait_for_stack_deletion $stack2_id $stack2_name $region

echo "Deleting $stack1_name id $stack1_id region $region"

delete_stack $stack1_id $stack1_name $region $stack1

echo "Waiting for $stack1 deletion"

wait_for_stack_deletion $stack1_id $stack1_name $region

echo "Done"
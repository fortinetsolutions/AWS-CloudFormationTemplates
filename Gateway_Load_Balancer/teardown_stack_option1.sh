#!/usr/bin/env bash

source $(dirname $0)/stack_parameters_option1.sh

delete_stack ()
{
    stack_name=$1
    if [ "$stack_name" != "" ]
    then
        aws cloudformation delete-stack --stack-name "$stack_name" --region "$region" > /dev/null
    fi
}

wait_for_stack_deletion ()
{
    stack_id=$1

    delete_complete=false
    while [ "$delete_complete" == false ]
    do
        arn_file=$(mktemp /tmp/wsdstack.XXXXXXXXX)
        aws cloudformation list-stacks  --region "$region" \
           --query "StackSummaries[?contains(StackId, '$stack_id')].{Name:StackName,Id:StackId,Status:StackStatus}" >$arn_file
        tname=`cat $arn_file |grep "$stack_id"|cut -f2 -d$'\t'`
        tarn=`cat $arn_file |grep "$stack_id"|cut -f1 -d$'\t'`
        tstatus=`cat $arn_file |grep "$stack_id"|cut -f3 -d$'\t'`
        if [ -f $arn_file ]
        then
            rm -f $arn_file
        fi
        if [ "$tname" == "$stack_name" ] && [ "$tarn" == "$stack_id" ] && [ "$tstatus" == "DELETE_COMPLETE" ]
        then
            echo
            delete_complete=true
        else
            echo -n "."
            sleep 15
        fi
    done
}

wait_for_stack_group_delete ()
{
    stack_group_file=$1
    arn_file=$2
    if [ "$stack_group_file" != "" ]
    then
        for i in `cat $stack_group_file`
        do
            if [ -f $arn_file ]
            then
                stack_id=`cat $arn_file |grep "$i"|cut -f1 -d$'\t'`
                stack_name=`cat $arn_file |grep "$i"|cut -f2 -d$'\t'`
            else
                stack_id=""
                stack_name=""
            fi
            if [ "$stack_id" != "" ] && [ "$stack_name" != "" ]
            then
                echo "Waiting for stack id = $stack_id"
                wait_for_stack_deletion $stack_id
            else
                echo "Skipping $i. Stack NOT FOUND"
            fi
        done
    else
        echo "delete_stack_group: Missing argument: 1 = $1 2 = $2"
    fi
}

delete_stack_group ()
{
    stack_group_file=$1
    arn_file=$2
    tfile=$2
    if [ "$stack_group_file" != "" ] && [ "$arn_file" != "" ]
    then
        for i in `cat $stack_group_file`
        do
            stack_id=`cat $tfile |grep "$i"|cut -f1 -d$'\t'`
            stack_name=`cat $tfile |grep "$i"|cut -f2 -d$'\t'`
            if [ "$stack_id" != "" ] && [ "$stack_name" != "" ]
            then
                echo "Deleting stack name = $stack_name"
                delete_stack $stack_name
            else
                echo "Skipping $i. Stack NOT FOUND"
            fi
        done
    else
        echo "delete_stack_group: Missing argument: 1 = $1 2 = $2"
    fi
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

#
# Stack group 1
gfile=$(mktemp /tmp/groupstack.XXXXXXXXX)
stack_group_1="$stack3c $stack3b $stack3a $stack3c1 $stack3b1 $stack3a1 $stack2a $stack2btg"
echo $stack_group_1 > $gfile
tfile=$(mktemp /tmp/foostack.XXXXXXXXX)
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" \
    --query "StackSummaries[*].{name:StackName,id:StackId,status:StackStatus}" >$tfile
delete_stack_group $gfile $tfile
wait_for_stack_group_delete $gfile $tfile
if [ -f $tfile ]
then
    rm -f $tfile
fi
if [ -f $gfile ]
then
    rm -f $gfile
fi

#
# Stack group 2
#
gfile=$(mktemp /tmp/groupstack.XXXXXXXXX)
stack_group_1="$stack1a $stack1b $stack1c $stack2c"
echo $stack_group_1 > $gfile
tfile=$(mktemp /tmp/foostack.XXXXXXXXX)
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" \
    --query "StackSummaries[*].{name:StackName,id:StackId}" >$tfile
delete_stack_group $gfile $tfile
wait_for_stack_group_delete $gfile $tfile
if [ -f $tfile ]
then
    rm -f $tfile
fi
if [ -f $gfile ]
then
    rm -f $gfile
fi

#
# Stack group 3
#
gfile=$(mktemp /tmp/groupstack.XXXXXXXXX)
stack_group_1="$stack2b"
echo $stack_group_1 > $gfile
tfile=$(mktemp /tmp/foostack.XXXXXXXXX)
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" \
    --query "StackSummaries[*].{name:StackName,id:StackId}" >$tfile
delete_stack_group $gfile $tfile
wait_for_stack_group_delete $gfile $tfile
if [ -f $tfile ]
then
    rm -f $tfile
fi
if [ -f $gfile ]
then
    rm -f $gfile
fi
#
# Stack group 4
#
gfile=$(mktemp /tmp/groupstack.XXXXXXXXX)
stack_group_1="$stack1s"
echo $stack_group_1 > $gfile
tfile=$(mktemp /tmp/foostack.XXXXXXXXX)
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" \
    --query "StackSummaries[*].{name:StackName,id:StackId}" >$tfile
delete_stack_group $gfile $tfile
wait_for_stack_group_delete $gfile $tfile
if [ -f $tfile ]
then
    rm -f $tfile
fi
if [ -f $gfile ]
then
    rm -f $gfile
fi

aws logs describe-log-groups --query 'logGroups[*].logGroupName' --output table --region $region | \
awk '{print $2}' | grep ^/aws/lambda/$project_name | while read x; do  echo "deleting $x" ; aws logs delete-log-group --log-group-name $x; done
echo "Done"
exit


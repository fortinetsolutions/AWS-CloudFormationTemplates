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

tfile=$(mktemp /tmp/foostack53.XXXXXXXXX)
aws ec2 describe-addresses --output text --region "$region" --query 'Addresses[?AssociationId==null]' > $tfile
for eipalloc in `cat "$tfile"|grep ^eipalloc |cut -f1 -d$'\t'`
do
    aws ec2 release-address --output text --region "$region" --allocation-id "$eipalloc"
done
if [ -f $tfile ]
then
    rm -f $tfile
fi

#
# Find the hosted zone id for the FortiManager domain we are using
#

publicip=`aws ec2 describe-addresses --output text --region "$region" --query "Addresses[?contains(PrivateIpAddress,'10.0.0.253')].{Public:PublicIp}"`

hosted_zone_id=`aws route53 list-hosted-zones --output text --region "$region" \
    --query "HostedZones[?contains(Name, '$domain.')].{Id:Id}"`

dns_name=`aws route53 list-resource-record-sets --output text --region "$region" \
    --hosted-zone-id "$hosted_zone_id" \
    --query "ResourceRecordSets[?contains(Name,'$fmgrprefix.$domain')].{Name:Name}"`

if [ "$dns_name" == ""$fmgrprefix"."$domain"." ]
then
    echo
    echo "Deleting FortiManager route53 record set for $publicip allocated for domain $fmgrprefix.$domain"
    echo
    tfile=$(mktemp /tmp/foostack53.XXXXXXXXX)
    aws route53 list-resource-record-sets --output text --region "$region" \
        --hosted-zone-id "$hosted_zone_id" \
        --query "ResourceRecordSets[?contains(Name,'$fmgrprefix.$domain')].{ResourceRecords:ResourceRecords}" >$tfile
    publicip=`cat $tfile|grep ^RESOURCERECORDS|cut -f2 -d$'\t'`
    if [ -f $tfile ]
    then
        rm -f $tfile
    fi
    if [ -e create_route53_resource.json ]
    then
        #
        # Create a route53 resource batch file to create an ALIAS record set for the FortiManager Public IP
        #
        tfile=$(mktemp /tmp/foostack53.XXXXXXXXX)
        cp create_route53_resource.json $tfile
        sed -i "s/{ACTION}/DELETE/g" $tfile
        sed -i "s/{COMMENT}/FortiManager DNS Name/g" $tfile
        sed -i "s/{DOMAIN}/$domain/g" $tfile
        sed -i "s/{DNSPREFIX}/$fmgrprefix/g" $tfile
        sed -i "s/{IPADDRESS}/$publicip/g" $tfile

        echo $hosted_zone_id
        cat $tfile
        aws route53 change-resource-record-sets --output text --region "$region" --hosted-zone-id $hosted_zone_id --change-batch file://$tfile
        if [ -f $tfile ]
        then
            rm -f $tfile
        fi
    fi
fi

assoc_id=`aws ec2 describe-addresses --output text --region "$region" --query "Addresses[?contains(PrivateIpAddress, '10.0.0.253')].{id:AssociationId}"`
alloc_id=`aws ec2 describe-addresses --output text --region "$region" --query "Addresses[?contains(PrivateIpAddress, '10.0.0.253')].{id:AllocationId}"`
if [ -n "$assoc_id" ]
then
    aws ec2 disassociate-address --region "$region" --association-id "$assoc_id"
    aws ec2 release-address --region "$region" --allocation-id "$alloc_id"
fi

#
# FortiAnalyzer Starts Here
#
tfile=$(mktemp /tmp/foostack53.XXXXXXXXX)
aws ec2 describe-addresses --output text --region "$region" --query 'Addresses[?AssociationId==null]' > $tfile
for eipalloc in `cat "$tfile"|grep ^eipalloc |cut -f1 -d$'\t'`
do
    aws ec2 release-address --output text --region "$region" --allocation-id "$eipalloc"
done
if [ -f $tfile ]
then
    rm -f $tfile
fi

#
# Find the hosted zone id for the domain we are using
#

publicip=`aws ec2 describe-addresses --output text --region "$region" --query "Addresses[?contains(PrivateIpAddress,'10.0.0.252')].{Public:PublicIp}"`

hosted_zone_id=`aws route53 list-hosted-zones --output text --region "$region" \
    --query "HostedZones[?contains(Name, '$domain.')].{Id:Id}"`

dns_name=`aws route53 list-resource-record-sets --output text --region "$region" \
    --hosted-zone-id "$hosted_zone_id" \
    --query "ResourceRecordSets[?contains(Name,'$fazprefix.$domain')].{Name:Name}"`

if [ "$dns_name" == ""$fazprefix"."$domain"." ]
then
    echo
    echo "Deleting FortiAnalyzer route53 record set for $publicip allocated for domain $fazprefix.$domain"
    echo
    if [ -e create_route53_resource.json ]
    then
        #
        # Create a route53 resource batch file to create an ALIAS record set for the FortiManager Public IP
        #

        tfile=$(mktemp /tmp/foostack53.XXXXXXXXX)
        aws route53 list-resource-record-sets --output text --region "$region" \
            --hosted-zone-id "$hosted_zone_id" \
            --query "ResourceRecordSets[?contains(Name,'$fazprefix.$domain')].{ResourceRecords:ResourceRecords}" >$tfile
        publicip=`cat $tfile|grep ^RESOURCERECORDS|cut -f2 -d$'\t'`
        if [ -f $tfile ]
        then
            rm -f $tfile
        fi
        tfile=$(mktemp /tmp/foostack53.XXXXXXXXX)
        cp create_route53_resource.json $tfile
        sed -i "s/{ACTION}/DELETE/g" $tfile
        sed -i "s/{COMMENT}/FortiAnalyzer DNS Name/g" $tfile
        sed -i "s/{DOMAIN}/$domain/g" $tfile
        sed -i "s/{DNSPREFIX}/$fazprefix/g" $tfile
        sed -i "s/{IPADDRESS}/$publicip/g" $tfile

        echo $hosted_zone_id

        aws route53 change-resource-record-sets --output text --region "$region" --hosted-zone-id $hosted_zone_id --change-batch file://$tfile
        if [ -f $tfile ]
        then
            rm -f $tfile
        fi
    fi
fi

assoc_id=`aws ec2 describe-addresses --output text --region "$region" --query "Addresses[?contains(PrivateIpAddress, '10.0.0.252')].{id:AssociationId}"`
alloc_id=`aws ec2 describe-addresses --output text --region "$region" --query "Addresses[?contains(PrivateIpAddress, '10.0.0.252')].{id:AllocationId}"`
if [ -n "$assoc_id" ]
then
    aws ec2 disassociate-address --region "$region" --association-id "$assoc_id"
    aws ec2 release-address --region "$region" --allocation-id "$alloc_id"
fi


tfile=$(mktemp /tmp/foostack.XXXXXXXXX)
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region "$region" \
    --query "StackSummaries[*].{name:StackName,id:StackId}" >$tfile
#
# break here
#
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

if [ -n "$stack7_name" ]
then
    echo "Deleting $stack7_name id $stack7_id region $region"
    delete_stack $stack7_id $stack7_name $region $stack7
fi

if [ -n "$stack6_name" ]
then
    echo "Deleting $stack6_name id $stack6_id region $region"
    delete_stack $stack6_id $stack6_name $region $stack6
fi

aws s3api head-bucket  --bucket $stack5-fortigate-config  2>/dev/null
if [ $? -eq 0 ]
then
    echo "Deleting bucket s3://$stack5-fortigate-configs"
    aws s3 rb s3://$stack5-fortigate-configs --force
fi

aws s3 rb s3://$stack5-fortigate-configs --force
if [ -n "$stack5_name" ]
then
    echo "Deleting $stack5_name id $stack5_id region $region"
    delete_stack $stack5_id $stack5_name $region $stack5
fi

if [ -n "$stack7_name" ]
then
    echo "Waiting for $stack7 deletion"
    wait_for_stack_deletion $stack7_id $stack7_name $region
fi

if [ -n "$stack6_name" ]
then
    echo "Waiting for $stack6 deletion"
    wait_for_stack_deletion $stack6_id $stack6_name $region
fi

if [ -n "$stack5_name" ]
then
    echo "Waiting for $stack5 deletion"
    wait_for_stack_deletion $stack5_id $stack5_name $region
fi

if [ -n "$stack4_name" ]
then
    echo "Deleting $stack4_name id $stack4_id region $region"
    delete_stack $stack4_id $stack4_name $region $stack4
fi

if [ -n "$stack3_name" ]
then
    echo "Deleting $stack3_name id $stack3_id region $region"
    delete_stack $stack3_id $stack3_name $region $stack3
fi

if [ -n "$stack2_name" ]
then
    echo "Deleting $stack2_name id $stack2_id region $region"
    delete_stack $stack2_id $stack2_name $region $stack2
fi

if [ -n "$stack4_name" ]
then
    echo "Waiting for $stack4 deletion"
    wait_for_stack_deletion $stack4_id $stack4_name $region
fi

if [ -n "$stack3_name" ]
then
    echo "Waiting for $stack3 deletion"
    wait_for_stack_deletion $stack3_id $stack3_name $region
fi

if [ -n "$stack2_name" ]
then
    echo "Waiting for $stack2 deletion"
    wait_for_stack_deletion $stack2_id $stack2_name $region
fi

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

echo "Done"

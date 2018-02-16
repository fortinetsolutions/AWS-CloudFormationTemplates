#!/usr/bin/env bash
usage()
{
cat << EOF
usage: $0 options

This script will build an AMI region map when provided an AMI description

OPTIONS:
   -s AMI search string
   -n AMI region map name
EOF
}

while getopts n:s: OPTION
do
     case $OPTION in
         s)
             SEARCH_STRING=$OPTARG
             SEARCH_SPECIFIED=true
             ;;
         n)
             NAME_STRING=$OPTARG
             NAME_SPECIFIED=true
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [ "$SEARCH_SPECIFIED" != "true" ] || [ "$NAME_SPECIFIED" != true ]
then
    echo "No search string specified or no name string specified"
    usage
    exit -1
fi

echo "    RegionMap: "

file=$(mktemp /tmp/abc-script.XXXXXX)
aws ec2 describe-regions --query 'Regions[*].{RegionName:RegionName}' | grep -v "ap-northeast-3" | sort > $file
for region in `cat $file`
do
	echo "      $region: "
	aid=`aws ec2 describe-images --region "$region" --filter "Name=name,Values=$SEARCH_STRING" --query 'Images[*].{ID:ImageId}'`
    echo "          $NAME_STRING: $aid"
done
if [ -f $file ]
then
    rm -f $file
fi

#!/bin/bash

bucketPrefix='fortibucket-'
#file1='aws-gd-fgt-lambda.zip'
#file2='aws-gd-otherregion-lambda.zip'
#file1='main_functionv2.zip'
#file2='worker_function.zip'
#file1='56_worker_function.zip'
#file1='56_worker_functionv2.zip'
#file3='spokevgw_functionv2.zip'
#file1='healthcheck.zip'
#file1='ap-healthcheck-v2.zip'
#file1='aa-healthcheck-v2.zip'
#file1='56_worker_functionv4.zip'
file1='autoscale-dev-v1.1.zip'

for region in `aws ec2 describe-regions --output text --query 'Regions[*].{RegionName:RegionName}'`
do
    echo "====== $region ====="
    regionalBucketName="$bucketPrefix$region"
    echo "regional bucket name: $regionalBucketName"
    aws s3 cp $file1 s3://$regionalBucketName --acl public-read
#    aws s3 cp $file2 s3://$regionalBucketName --acl public-read
#    aws s3 cp $file3 s3://$regionalBucketName --acl public-read
done

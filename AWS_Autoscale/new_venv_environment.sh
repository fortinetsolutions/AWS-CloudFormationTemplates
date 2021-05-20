#!/bin/bash
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt-get update

sudo apt-get install awscli -y

tput clear
echo
echo "Provide AWS Credentials via "aws configure" and deployment specific parameters"
echo
echo
aws configure
echo "export AWS_ACCESS_KEY_ID=`aws configure get aws_access_key_id`" >> ~/.bashrc
echo "export AWS_SECRET_ACCESS_KEY=`aws configure get aws_secret_access_key`" >> ~/.bashrc
echo "export AWS_REGION=`aws configure get region`" >> ~/.bashrc
source ~/.bashrc
#
# Ask the user which region to deploy to
#
echo -n "Which aws region would you like to deploy in: "
read userInput
if [[ -n "$userInput" ]]
then
    region=$userInput
fi

#
# Ask the user for an s3 bucket name that doesn't exist
#
echo -n "Provide a unique S3 Bucket for the deployment to use: "
read userInput
if [[ -n "$userInput" ]]
then
    s3_bucket=$userInput
fi

#
# Ask the user for a keypair that exists in the region
#
echo -n "Provide a region specific keypair ec2 instances to use: "
read userInput
if [[ -n "$userInput" ]]
then
    keypair=$userInput
fi
#
# Ask the user for a customer prefix that will be used to tag all the resources in the deployment
#
echo -n "Provide a customer prefix that will be used to name all the deployment resources: "
read userInput
if [[ -n "$userInput" ]]
then
    customer_prefix=$userInput
fi
#
# Ask the user for a environment tag (prod/dev/test etc.) that will be used to tag all the resources in the deployment
#
echo -n "Provide a deployment environment tag (prod/dev/test) that will be used to name all the deployment resources: "
read userInput
if [[ -n "$userInput" ]]
then
    customer_environment=$userInput
fi
tput clear

sudo apt remove python python3.5 python3.6 python3.7 --yes
sudo apt-get install python3.7 python3.7-venv python3-pip --yes
sudo apt-get upgrade --yes
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip3 install -r requirements.txt
sudo apt install snap snapd --yes
sudo snap install terraform

#
# Now modify the appropriate files based on user input
#
# replace everything between the two quotes on the line that starts with aws_region with the region user input
# then build the availability zones using the region... its assumed that it will be 1a and 1b
#
sed -i '/^aws_region/ s/"[^"][^"]*"/"'$region'"/' ./terraform/terraform.tfvars
sed -i '/^availability_zone1/ s/"[^"][^"]*"/"'$region'a"/' ./terraform/terraform.tfvars
sed -i '/^availability_zone2/ s/"[^"][^"]*"/"'$region'b"/' ./terraform/terraform.tfvars
sed -i '/^customer_prefix/ s/"[^"][^"]*"/"'$customer_prefix'"/' ./terraform/terraform.tfvars
sed -i '/^environment/ s/"[^"][^"]*"/"'$customer_environment'"/' ./terraform/terraform.tfvars
#
# replace everything between the second set of two quotes on the line that contains with "aws_region":
# with the region user input for the autoscale/zappa_settings.json file
#
sed -i '/"aws_region":/ s/"[^"][^"]*"/"'$region'"/2' ./lambda_code/autoscale/zappa_settings.json
#
# replace everything between the second set of two quotes on the line that contains with "s3_bucket":
# with the s3_bucket user input for the autoscale/zappa_settings.json file
#
sed -i '/"s3_bucket":/ s/"[^"][^"]*"/"'$s3_bucket'"/2' ./lambda_code/autoscale/zappa_settings.json
#
# replace everything between the set of two quotes on the line that contains with "keypair":
# with the keypair user input for the terraform.tfvars file
#
sed -i '/^keypair/ s/"[^"][^"]*"/"'$keypair'"/' ./terraform/terraform.tfvars

tput clear
echo "Verify the ./terraform/terraform.tfvars and ./lambda_code/autoscale/zappa_settings.json file for correct parameters"

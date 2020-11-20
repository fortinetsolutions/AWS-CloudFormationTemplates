#!/usr/bin/env bash


#
# variables for entire stack set
#
region=us-west-2

stack_prefix=gwlb3
environment_tag=dev
project_name=$stack_prefix-beta

#
# Cloudinit stack names that build the AGW Stacks
#
#
# Base VPC Templates. (VPC's, Subnets, Route Tables, IGW's, etc)
# Not used if deploying into an existing VPC.
#
stack1s=$project_name-security
stack1t=$project_name-tgw
stack1a=$project_name-customer-a

#
# Templates to deploy Security VPC Fortigate's and Customer Endpoints
#
stack2a=$project_name-deploy-security-vpc-fgt
stack2b=$project_name-deploy-gateway-lb
stack2btg=$project_name-deploy-gateway-tg
stack2c=$project_name-deploy-endpoint-service
stack2d=$project_name-deploy-security-instance
stack2e=$project_name-vpce-az1
stack2f=$project_name-vpce-az2
stack3a=$project_name-li-ca

#
# Security VPC Firewall Set variables
#
# This value needs to be changed. Account Specific
#
key=mdw-key-oregon
license_bucket=mdw-license-bucket-us-west-2
access_public="24.242.248.10/32"
#
# Values that might work across accounts
#
config_bucket=$stack_prefix-ha-$region
admin_password="Texas4me!"
linux_instance_type=t2.micro
linux_health_check_port="22"
fgt_instance_type=c5n.xlarge
s3_endpoint_condition=UseExisting
license_type=PAYG
fortigate1_license_file=fgt1-license.lic
fortigate2_license_file=fgt2-license.lic
access_private="0.0.0.0/0"
privateaccess="10.0.0.0/16"

#
# Variables for Appliance Gateway
#
tgw_name=$project_name-tgw
gwlb_name=$project_name-gateway-lb
gwlb_target_group_name=$project_name-gwlb-tg
gwlb_target_group_port=6081
gwlb_health_port=443
gwlb_health_protocol="HTTPS"

#
# Variables for VPC Endpoints
#
AcceptConnection=false
AwsAccountToWhitelist="arn:aws:iam::123073262904:root"
#
# Variables for Security VPC
#
ha_cidr="10.0.0.0/25"
#
# Variables for Security VPC AZ 1
ha_public1_subnet="10.0.0.0/28"
ha_private1_subnet="10.0.0.16/28"
ha_tgw1_subnet="10.0.0.32/28"
fortigate1_public_ip="10.0.0.7/28"
#
# The Private IP address can be recalculated if it conflicts with Load Balancer IP
#
fortigate1_private_ip="10.0.0.23/28"

#
# Variables for Security VPC AZ 2
#
ha_public2_subnet="10.0.0.64/28"
ha_private2_subnet="10.0.0.80/28"
ha_tgw2_subnet="10.0.0.96/28"

fortigate2_public_ip="10.0.0.71/28"
#
# The Private IP address can be recalculated if it conflicts with Load Balancer IP
#
fortigate2_private_ip="10.0.0.87/28"

#
# Variables for UserInit Data that is used for bootstrap code for each Fortigate
#
public1_subnet_router="10.0.0.1"
private1_subnet_router="10.0.0.17"

public2_subnet_router="10.0.0.65"
private2_subnet_router="10.0.0.81"

#
# Customer A VPC variables
#
customer_a_cidr="192.168.0.0/25"
customer_a_public_subnet="192.168.0.0/28"
customer_a_az="$region"a
customer_a_private_ip="192.168.0.13"

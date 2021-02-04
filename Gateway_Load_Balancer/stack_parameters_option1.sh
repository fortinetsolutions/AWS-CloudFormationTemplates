#!/usr/bin/env bash


#
# variables for entire stack set
#
region=us-west-2

stack_prefix=gwlb1
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
stack1a=$project_name-customer-a
stack1b=$project_name-customer-b
stack1c=$project_name-customer-c

#
# Templates to deploy Security VPC Fortigate's and Customer Endpoints
#
stack2a=$project_name-deploy-security-vpc-fgt
stack2b=$project_name-deploy-gateway-lb
stack2btg=$project_name-deploy-gateway-tg
stack2c=$project_name-deploy-endpoint-service
stack2d=$project_name-deploy-security-instance
stack3a=$project_name-li-ca
stack3a1=$project_name-ca-vpce
stack3b=$project_name-li-cb
stack3b1=$project_name-cb-vpce
stack3c=$project_name-li-cc
stack3c1=$project_name-cc-vpce

#
# Security VPC Firewall Set variables
#
# This value needs to be changed. Account Specific
#
key=mdw-key-oregon
license_bucket=mdw-license-bucket-us-west-2
access_public="0.0.0.0/0"

#
# These should work across accounts
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
ha_sync1_subnet="10.0.0.32/28"
ha_mgmt1_subnet="10.0.0.48/28"
fortigate1_public_ip="10.0.0.7/28"
#
# The Private IP address can be recalculated if it conflicts with Load Balancer IP
#
fortigate1_private_ip="10.0.0.23/28"
fortigate1_sync_ip="10.0.0.39/28"
fortigate1_mgmt_ip="10.0.0.55/28"

#
# Variables for Security VPC AZ 2
#
ha_public2_subnet="10.0.0.64/28"
ha_private2_subnet="10.0.0.80/28"
ha_sync2_subnet="10.0.0.96/28"
ha_mgmt2_subnet="10.0.0.112/28"
fortigate2_public_ip="10.0.0.71/28"
#
# The Private IP address can be recalculated if it conflicts with Load Balancer IP
#
fortigate2_private_ip="10.0.0.87/28"
fortigate2_sync_ip="10.0.0.103/28"
fortigate2_mgmt_ip="10.0.0.119/28"

#
# Variables for UserInit Data that is used for bootstrap code for each Fortigate
#
public1_subnet_router="10.0.0.1"
private1_subnet_router="10.0.0.17"
sync1_subnet_router="10.0.0.33"
ha_mgmt1_subnet_router="10.0.0.49"
public2_subnet_router="10.0.0.65"
private2_subnet_router="10.0.0.81"
sync2_subnet_router="10.0.0.97"
ha_mgmt2_subnet_router="10.0.0.113"

#
# Customer A VPC variables
#
customer_a_cidr="192.168.0.0/25"
customer_a_public_subnet="192.168.0.0/28"
customer_a_private_subnet="192.168.0.16/28"
customer_a_az="$region"a

#
# Customer B VPC variables
#
customer_b_cidr="192.168.1.0/25"
customer_b_public_subnet="192.168.1.0/28"
customer_b_private_subnet="192.168.1.16/28"
customer_b_az="$region"a

#
# Customer C VPC variables
#
customer_c_cidr="192.168.2.0/25"
customer_c_public_subnet="192.168.2.0/28"
customer_c_private_subnet="192.168.2.16/28"
customer_c_az="$region"a

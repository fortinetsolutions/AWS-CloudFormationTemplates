#!/usr/bin/env bash


#
# variables
#
region=us-west-2

stack_prefix=mdw
environment_tag=dev
project_name=$stack_prefix-ha

stack1=$project_name-base
stack2=$project_name-ha-public
stack3=$project_name-ha-private

config_bucket=$stack_prefix-ha-$region
lambda_bucket=fortimdw
key=mdw-key-oregon

ha_cidr="10.0.0.0/16"
ha_public_subnet1="10.0.1.0/24"
ha_public_subnet2="10.0.10.0/24"
ha_middle_subnet1="10.0.2.0/24"
ha_middle_subnet2="10.0.20.0/24"
ha_private_subnet1="10.0.3.0/24"
ha_private_subnet2="10.0.30.0/24"
ha_sync_subnet1="10.0.4.0/24"
ha_sync_subnet2="10.0.40.0/24"
ha_mgmt_subnet1="10.0.5.0/24"
ha_mgmt_subnet2="10.0.50.0/24"
public_subnet1_router="10.0.1.1"
middle_subnet1_router="10.0.2.1"
private_subnet1_router="10.0.3.1"
hamgmt_subnet1_router="10.0.5.1"
public_subnet2_router="10.0.10.1"
middle_subnet2_router="10.0.20.1"
private_subnet2_router="10.0.30.1"
hamgmt_subnet2_router="10.0.50.1"
fortigate1_public_ip="10.0.1.10/24"
fortigate1_middle_ip="10.0.2.10/24"
fortigate1_sync_ip="10.0.4.10/24"
fortigate1_mgmt_ip="10.0.5.10/24"
fortigate2_public_ip="10.0.10.10/24"
fortigate2_middle_ip="10.0.20.10/24"
fortigate2_sync_ip="10.0.40.10/24"
fortigate2_mgmt_ip="10.0.50.10/24"
fortigate3_middle_ip="10.0.2.11/24"
fortigate3_private_ip="10.0.3.11/24"
fortigate3_sync_ip="10.0.4.11/24"
fortigate3_mgmt_ip="10.0.5.11/24"
fortigate4_middle_ip="10.0.20.11/24"
fortigate4_private_ip="10.0.30.11/24"
fortigate4_sync_ip="10.0.40.11/24"
fortigate4_mgmt_ip="10.0.50.11/24"

fgt_instance_type=c5n.xlarge
s3_endpoint_condition=UseExisting
license_type=BYOL
license_bucket=mdw-license-bucket-us-west-2
license_bucket2=mdw-license-bucket2-us-west-2
fortigate1_license_file=fgt1-license.lic
fortigate2_license_file=fgt2-license.lic
fortigate3_license_file=fgt3-license.lic
fortigate4_license_file=fgt4-license.lic

access_private="0.0.0.0/0"
access_public="107.220.179.27/32"
privateaccess="10.0.0.0/16"

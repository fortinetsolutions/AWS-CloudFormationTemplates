#!/usr/bin/env bash

stack_prefix=mdw
stack1=$stack_prefix-base
stack2=$stack_prefix-ws
stack3=$stack_prefix-tg
stack5=$stack_prefix-fwrk
stack6=$stack_prefix-asg
stack7=$stack_prefix-paygo-asg

region=us-west-2

config_bucket=mdw-config
lambda_bucket=fortimdw
license_bucket=mdw-license-bucket-us-west-2
password_parameter_name="/mdw/dev/password"
admin_https_port=443
lb_dns_name=mdw-lb-dbc9d5f4ee5e9c0c.elb.us-east-1.amazonaws.com
api_gateway=https://3zco01g4v3.execute-api.us-east-1.amazonaws.com/dev/sns
config_object=current.conf
domain=fortimdw.com
fgtdns=$stack_prefix-fortias
fmgrprefix=$stack_prefix-fortimanager
fazprefix=$stack_prefix-fortianalyzer
webdns=httpservermdw
admin_port=443
cooldown=300
environment_tag=dev

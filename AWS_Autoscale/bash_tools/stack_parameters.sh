#!/usr/bin/env bash

stack_prefix=mdw
stack1=$stack_prefix-base
stack2=$stack_prefix-addprivatelinux
stack3=$stack_prefix-addpubliclinux
stack5=$stack_prefix-framework
stack6=$stack_prefix-asg

region=us-east-1

config_bucket=mdw-autoscale
license_bucket=asg-mdw-licenses
lb_dns_name=arn:aws:elasticloadbalancing:us-east-1:730386877786:loadbalancer/net/mdw-addprivatelinux-WebELB/97fac67dce808c7d
config_object=current.conf
domain=fortiengineering.com
fgtdns=$stack_prefix-fortias
fmgrprefix=$stack_prefix-fortimanager
fazprefix=$stack_prefix-fortianalyzer
webdns=httpservermdw
admin_port=443
cooldown=300

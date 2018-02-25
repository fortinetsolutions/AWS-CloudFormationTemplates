#!/usr/bin/env bash

stack_prefix=mdw
stack1=$stack_prefix-base
stack2=$stack_prefix-addprivatelinux
stack3=$stack_prefix-addpubliclinux
stack4=$stack_prefix-fgt
stack5=$stack_prefix-autoscale
stack6=$stack_prefix-fortimanager
stack7=$stack_prefix-fortianalyzer

region=us-east-1

config_bucket=$stack_prefix-config
config_object=current.conf
config_object_b=current-b.conf
domain=fortidevelopment.com
fgtdns=$stack_prefix-fortias
fmgrprefix=$stack_prefix-fortimanager
fazprefix=$stack_prefix-fortianalyzer
webdns=httpservermdw

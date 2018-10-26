config system global
set hostname fgt-2
set admintimeout 60
end
config system interface
edit port1
set mode static
set ip ${fgt2_public_ip}
set allowaccess https ping ssh fgfm
set alias public
next
edit port2
set mode static
set ip ${fgt2_private_ip}
set allowaccess ping
set alias private
next
edit port3
set mode static
set ip ${fgt2_hasync_ip}
set allowaccess ping
set alias hasync
next
edit port4
set mode static
set ip ${fgt2_hamgmt_ip}
set allowaccess https ping ssh
set alias hamgmt
next
end
config router static
edit 1
set device port1
set gateway ${public_subnet_intrinsic_router_ip}
next
edit 2
set device port2
set dst ${vpc_cidr}
set gateway ${private_subnet_intrinsic_router_ip}
next
end
config firewall policy
edit 1
set name outbound-all
set srcintf port2
set dstintf port1
set srcaddr all
set dstaddr all
set action accept
set schedule always
set service ALL
set logtraffic all
set nat enable
next
end
config system ha
set group-name group1
set mode a-p
set hbdev port3 50
set session-pickup enable
set ha-mgmt-status enable
config ha-mgmt-interface
edit 1
set interface port4
set gateway ${hamgmt_subnet_intrinsic_router_ip}
next
end
set override disable
set priority 1
set unicast-hb enable
set unicast-hb-peerip ${fgt1_hasync_ip}
end
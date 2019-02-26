config system global
set hostname ${fgt_id}
set admintimeout 30
end

config vpn ipsec phase1-interface
edit "tgw-vpn1"
set interface "port1"
set local-gw ${fgt_ip}
set keylife 28800
set peertype any
set proposal aes128-sha1
set dhgrp 2
set remote-gw ${t1_ip}
set psksecret ${t1_psk}
set dpd-retryinterval 10
next
edit "tgw-vpn2"
set interface "port1"
set local-gw ${fgt_ip}
set keylife 28800
set peertype any
set proposal aes128-sha1
set dhgrp 2
set remote-gw ${t2_ip}
set psksecret ${t2_psk}
set dpd-retryinterval 10
next
end

config vpn ipsec phase2-interface
edit "tgw-vpn1"
set phase1name "tgw-vpn1"
set proposal aes128-sha1
set dhgrp 2
set keylifeseconds 3600
next
edit "tgw-vpn2"
set phase1name "tgw-vpn2"
set proposal aes128-sha1
set dhgrp 2
set keylifeseconds 3600
next
end

config system interface
edit "loopback"
set type loopback
set vdom "root"
set ip ${fgt_lpb} 255.255.255.255
set allowaccess ping https ssh fgfm
next
edit "tgw-vpn1"
set description ${t1_id}
set ip ${t1_lip} 255.255.255.255
set remote-ip ${t1_rip} 255.255.255.255
next
edit "tgw-vpn2"
set description ${t2_id}
set ip ${t2_lip} 255.255.255.255
set remote-ip ${t2_rip} 255.255.255.255
next
end

config system zone
edit "transit-gw"
set interface "tgw-vpn1" "tgw-vpn2"
next
end

config firewall ippool
edit "ippool"
set startip ${fgt_lpb}
set endip ${fgt_lpb}
next
end

config firewall policy
edit 1
set name "vpc-loopback_access"
set srcintf "transit-gw"
set dstintf "loopback"
set srcaddr "all"
set dstaddr "all"
set action accept
set schedule "always"
set service "ALL"
set utm-status enable
set logtraffic all
set ips-sensor "default"
set application-list "default"
set ssl-ssh-profile "certificate-inspection"
next
edit 2
set name "vpc-vpc_access"
set srcintf "transit-gw"
set dstintf "transit-gw"
set srcaddr "all"
set dstaddr "all"
set action accept
set schedule "always"
set service "ALL"
set utm-status enable
set logtraffic all
set ippool enable
set poolname "ippool"
set av-profile "default"
set webfilter-profile "default"
set ips-sensor "default"
set application-list "default"
set ssl-ssh-profile "certificate-inspection"
set nat enable
next
edit 3
set name "vpc-internet_access"
set srcintf "transit-gw"
set dstintf "port1"
set srcaddr "all"
set dstaddr "all"
set action accept
set schedule "always"
set service "ALL"
set utm-status enable
set logtraffic all
set av-profile "default"
set webfilter-profile "default"
set ips-sensor "default"
set application-list "default"
set ssl-ssh-profile "certificate-inspection"
set nat enable
next
end

config router prefix-list
edit "pflist-default-route"
config rule
edit 1
set prefix 0.0.0.0 0.0.0.0
unset ge
unset le
next
end
next
edit "pflist-loopback"
config rule
edit 1
set prefix ${fgt_lpb} 255.255.255.255
unset ge
unset le
next
end
next
end

config router route-map
edit "rmap-outbound"
config rule
edit 1
set match-ip-address "pflist-default-route"
next
edit 2
set match-ip-address "pflist-loopback"
next
end
next
end

config router bgp
set as ${fgt_bgp}
set router-id ${fgt_lpb}
set ebgp-multipath enable
config neighbor
edit ${t1_rip}
set description ${t1_id}
set capability-default-originate enable
set remote-as ${t1_bgp}
set route-map-out "rmap-outbound"
set link-down-failover enable
next
edit ${t2_rip}
set description ${t2_id}
set capability-default-originate enable
set remote-as ${t2_bgp}
set route-map-out "rmap-outbound"
set link-down-failover enable
next
end
config redistribute "connected"
set status enable
end
end
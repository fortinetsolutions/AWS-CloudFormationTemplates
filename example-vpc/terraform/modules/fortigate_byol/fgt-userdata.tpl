Content-Type: multipart/mixed; boundary="===============0086047718136476635=="
MIME-Version: 1.0

--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config"

config system global
set hostname ${fgt_id}
set admintimeout 30
end

config system interface
edit port1
set alias public
set mode dhcp
set allowaccess ping https ssh fgfm
next
edit port2
set alias private
set mode dhcp
set allowaccess ping https ssh fgfm
end

config system admin
edit "admin"
set password ${fgt_admin_password}
next
end

config firewall policy
edit 0
set name outbound-all
set srcintf port2
set dstintf port1
srcaddr all
set dstaddr all
action accept
schedule always
service ALL
logtraffic all
set nat enable
next
end

--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="license"

${fgt_byol_license}

--===============0086047718136476635==--
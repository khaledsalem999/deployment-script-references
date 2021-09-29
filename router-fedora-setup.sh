#!/bin/bash
if [ -z $1 ]
then
    RUN_BY=`who | awk '{print $1}'`
else
    RUN_BY=$1
fi
RUN_BY_HOME=`/bin/bash -c "echo ~$RUN_BY"`
echo "Run by $RUN_BY with home $RUN_BY_HOME"

# Install VPN
dnf -y install openconnect vpnc-script

# Add VPNC scripts
mkdir -p /etc/vpnc/pre-init.d
cat << 'EOF' > /etc/vpnc/pre-init.d/banque-misr
#!/bin/bash
echo "pre-init"
EOF
mkdir -p /etc/vpnc/post-connect.d
cat << 'EOF' > /etc/vpnc/post-connect.d/banque-misr
#!/bin/bash
echo "post-connect"
route del -net 0.0.0.0 dev $TUNDEV
route add -net 192.168.0.0/16 dev $TUNDEV
echo "nameserver 8.8.8.8" > /etc/resolve.conf
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
iptables -A INPUT -i enp0s5 -j ACCEPT
iptables -A INPUT -i tun0 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -j ACCEPT
echo "router configured"
EOF
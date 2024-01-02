#!/bin/sh
#!/bin/bash

#Variables
IP='some external IP'
WG_PORT='13920'
WGUI_PORT='13908'

SslKeyPath='/etc/nginx/ssl/priv.key'
SslCertPath='/etc/nginx/ssl/ssl.crt'
UiScreen=$(screen -ls | grep Detached | awk '{print $1}')
PasswordGenerator=$(</dev/urandom tr -dc '[:alnum:]' | head -c15; echo "")
now=$(date +'%Y-%m-%dT%H:%M:%S.%NZ')
PresharedKeyGen=$(openssl rand -base64 32)

#Update software and install curl. 
apt update
apt install -y curl nginx make


#Install Go
cd /tmp 
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
tar xzvf go*
mv go /opt/go
ln -s /opt/go/bin/go /usr/bin/go 
go version

#Install WireGuard
apt install -y wireguard-tools --no-install-recommends
wget -O /usr/local/src/wireguard-go.tar.xz  https://git.zx2c4.com/wireguard-go/snapshot/wireguard-go-0.0.20230223.tar.xz
tar xvf /usr/local/src/wireguard-go.tar.xz  --directory /usr/local/src/
cd /usr/local/src/wireguard-go-*

# fix wireguard conf to smaller memory consumption
rm ./device/queueconstants_default.go
tee ./device/queueconstants_default.go <<EOF
//go:build !android && !ios && !windows

/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package device

const (
	QueueStagedSize            = 128
	QueueOutboundSize          = 1024
	QueueInboundSize           = 1024
	QueueHandshakeSize         = 1024
	MaxSegmentSize             = 1700 // largest possible UDP datagram
	PreallocatedBuffersPerPool = 1024 // Disable and allow for infinite memory growth
)
EOF

make
cp /usr/local/src/wireguard-go-*/wireguard-go /usr/local/bin 

#Install GUI
wget -P /usr/local/src/ui https://github.com/ngoduykhanh/wireguard-ui/releases/download/v0.5.2/wireguard-ui-v0.5.2-linux-amd64.tar.gz
tar xvf /usr/local/src/ui/wireguard-ui-* --directory /usr/local/src/ui

#Cleaning after the installation 
apt clean
rm -rf /usr/local/src/ui/*.tar.gz 
rm -rf /usr/local/src/*.tar.xz
rm -rf /tmp/*.tar.gz 

#Setting up services for the GUI
tee /etc/systemd/system/wgui.service <<EOF
[Unit]
Description=Restart WireGuard
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/systemctl restart wg-quick@wg0.service

[Install]
RequiredBy=wgui.path
EOF

tee /etc/systemd/system/wgui.path <<EOF
[Unit]
Description=Watch /etc/wireguard/wg0.conf for changes

[Path]
PathModified=/etc/wireguard/wg0.conf

[Install]
WantedBy=multi-user.target
EOF

#Generate SSL key and cert. 
mkdir /etc/nginx/ssl
openssl genrsa -out /etc/nginx/ssl/priv.key 2048
printf '\n\n\n\n\n\n\n\n' | openssl req -key /etc/nginx/ssl/priv.key -new -x509 -days 365 -out /etc/nginx/ssl/ssl.crt

#Configure proxy-pass for nginx to the UI
tee /etc/nginx/sites-available/ui.conf <<EOF
server {

    listen              $WGUI_PORT ssl;
    listen              [::]:$WGUI_PORT ssl;
    error_page 497 https://$IP:$WGUI_PORT;
    server_name         $IP;
    root                /var/www/html/;
    error_log   /dev/null   crit;
    access_log  /dev/null;

    # SSL
    ssl_certificate     $SslCertPath;
    ssl_certificate_key $SslKeyPath;

    # reverse proxy
    location / {
        proxy_pass http://127.0.0.1:5000;

    }

}
EOF

ln -s /etc/nginx/sites-available/ui.conf /etc/nginx/sites-enabled/ui.conf
rm -rf /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default

#Start GUI for first time so that the files can be generated. 
tee -a /etc/systemd/system/wireguard-ui.service <<EOF
{
[Unit]
Description=wireguard-ui

[Service]
User=root
WorkingDirectory=/usr/local/src/ui
ExecStart=/usr/local/src/ui/wireguard-ui
Restart=always

[Install]
WantedBy=multi-user.target
}
EOF

systemctl start wireguard-ui.service
while ! netstat -tulpn | grep -q '5000'; do
  echo 'wait wireguard-ui.service:5000'
  sleep 2
done
systemctl stop wireguard-ui.service

#Generate Client keys
wg genkey | tee /etc/wireguard/dedicatedvpn_private_key | wg pubkey > /etc/wireguard/dedicatedvpn_public_key

ClientPrivateKey=$(cat /etc/wireguard/dedicatedvpn_private_key)
ClientPubkey=$(cat /etc/wireguard/dedicatedvpn_public_key)

#Append initial config to the UI
tee /usr/local/src/ui/db/server/global_settings.json <<EOF
{
        "endpoint_address": "$IP",
         "dns_servers": [
				"1.1.1.1",
				"8.8.8.8",
                "9.9.9.9"
        ],
        "mtu": "1450",
        "persistent_keepalive": "15",
        "config_file_path": "/etc/wireguard/wg0.conf",
        "updated_at": "$now"
}
EOF

tee /usr/local/src/ui/db/server/interfaces.json <<EOF
{
        "addresses": [
                "10.0.3.1/24"
        ],
        "listen_port": "$WG_PORT",
		"updated_at": "$now"
}
EOF

rm /usr/local/src/ui/db/users/admin.json
tee /usr/local/src/ui/db/users/admin.json <<EOF
{
        "username": "admin",
        "password": "$PasswordGenerator",
        "admin": true
}
EOF

tee /usr/local/src/ui/db/clients/c8lk2jip7fiao760lhq0.json <<EOF
{
        "id": "c8lk2jip7fiao760lhq0",
        "private_key": "$ClientPrivateKey",
        "public_key": "$ClientPubkey",
        "preshared_key": "$PresharedKeyGen",
        "name": "dedicatedvpn",
        "email": "noreply@vpn.vpn",
        "allocated_ips": [
                "10.0.3.2/32"
        ],
        "allowed_ips": [
                "0.0.0.0/0"
        ],
        "extra_allowed_ips": [],
        "use_server_dns": true,
        "enabled": true,
        "created_at": "$now",
        "updated_at": "$now"
}
EOF

#Create a default wg0 conf for initial config
WireguardPrivateKey=$(cat /usr/local/src/ui/db/server/keypair.json | grep private | awk '{print $2}' | cut -d '"' -f2)

tee /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.0.3.1/24
ListenPort = $WG_PORT
PrivateKey = $WireguardPrivateKey
MTU = 1450
PostUp = ufw route allow in on wg0 out on eth0; iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE; ip6tables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
PostDown = ufw route delete allow in on wg0 out on eth; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = $ClientPubkey
PresharedKey = $PresharedKeyGen
AllowedIPs = 10.0.3.2/32
EOF

#Start all of the needed services
systemctl start wg-quick@wg0 
systemctl start wgui.service
systemctl start wgui.path
systemctl start wireguard-ui.service
systemctl restart nginx

systemctl enable wireguard-ui.service
systemctl enable wg-quick@wg0 
systemctl enable wgui.path
systemctl enable wgui.service

#Remove bloatware & update
# apt purge libpython* exim* apache2* python* pwgen tcpdump telnet -y 
# apt clean
# reboot

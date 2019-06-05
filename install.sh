#!/bin/bash

#install Shadowsocks on CentOS 7

echo "Installing Shadowsocks..................................................."

CONFIG_FILE=/etc/shadowsocks.json
SS_SERVICE_FILE=/etc/systemd/system/ssserver.service
SS_PASSWORD=bluesone
SS_PORT=2101

yum update -y
yum install -y python-setuptools && easy_install pip
pip install shadowsocks


# creat shadowsocks config

cat << EOF | tee ${CONFIG_FILE}
{
    "server":"0.0.0.0",
    "server_port":${SS_PORT},
    "local_address": "127.0.0.1",
    "local_port":1080,
    "password":"${SS_PASSWORD}",
    "timeout":600,
    "method":"aes-256-cfb",
    "fast_open": false
}
EOF

#install m2crypto
yum install m2crypto gcc -y
yum -y install wget
wget -N --no-check-certificate https://download.libsodium.org/libsodium/releases/libsodium-1.0.16.tar.gz
tar zfvx libsodium-1.0.16.tar.gz
 cd libsodium-1.0.16
./configure
make && make install
echo "include ld.so.conf.d/*.conf" > /etc/ld.so.conf
echo "/lib" >> /etc/ld.so.conf
echo "/usr/lib64" >> /etc/ld.so.conf
echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig

# set shadowssocks.service start with system

echo "create ${SS_SERVICE_FILE} && set ssserver.service start with system......"

cat << EOF | tee ${SS_SERVICE_FILE}
[Unit]
Description=ssserver
[Service]
TimeoutStartSec=0
ExecStart=/usr/bin/ssserver -c ${CONFIG_FILE}
[Install]
WantedBy=multi-user.target
EOF

echo "start ssserver.service .................................................."

systemctl start ssserver
systemctl enable ssserver

echo "status ssserver.service ................................................."

systemctl status ssserver -l

#install firewalld
yum install firewalld -y
/bin/systemctl start  firewalld.service
firewall-cmd --zone=public --permanent --add-port=${SS_PORT}/tcp
firewall-cmd --reload
sudo firewall-cmd --zone=public --list-ports

echo "Done................................................................."

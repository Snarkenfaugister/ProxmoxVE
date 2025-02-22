#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Snarkenfaugister
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DumbWareio/DumbWhoIs

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  npm 
msg_ok "Installed Dependencies"

msg_info "Setup DumbWhois"
cd /opt
wget -q "https://github.com/DumbWareio/DumbWhoIs/archive/refs/heads/main.zip"
unzip -q main.zip
mv DumbWhoIs-main/ /opt/DumbWhois

cd /opt/DumbWhois
npm install
cp .env.example .env
msg_ok "Setup Pocket ID"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/dumb-whois.service
[Unit]
Description=DumbWhois
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/DumbWhois
EnvironmentFile=/opt/DumbWhois/.env
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
msg_ok "Created Service"

msg_info "Starting Services"
systemctl enable -q --now dumb-whois
msg_ok "Started Services"

motd_ssh
customize

msg_info "Cleaning up"
rm -f /opt/main.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize

#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Snarkenfaugister
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/stonith404/pocket-id

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
  git
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install pm2 -g
msg_ok "Installed Node.js"

msg_info "Installing Golang"
cd /tmp
set +o pipefail
GO_RELEASE=$(curl -s https://go.dev/dl/ | grep -o -m 1 "go.*\linux-amd64.tar.gz")
wget -q https://golang.org/dl/${GO_RELEASE}
tar -xzf ${GO_RELEASE} -C /usr/local
ln -s /usr/local/go/bin/go /usr/bin/go
set -o pipefail
msg_ok "Installed Golang"

msg_info "Setup ${APP}"
RELEASE=$(curl -s https://api.github.com/repos/stonith404/pocket-id/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
git clone https://github.com/stonith404/pocket-id /opt/pocket-id
cd /opt/pocket-id
git fetch --tags && git checkout $(git describe --tags `git rev-list --tags --max-count=1`)
cd pocket-id/backend
cp .env.example .env
cd cmd
$STD go build -o ../pocket-id-backend
cd ../frontend
cp .env.example .env
$STD npm install
$STD npm run build
echo "${RELEASE}" >/opt/${APP}_version.txt
msg_ok "Setup ${APP}"

msg_info "Starting ${APP}"
$STD pm2 start /opt/pocket-id/backend/pocket-id-backend --name pocket-id-backend
$STD pm2 start /opt/pocket-id/frontend/build/index.js --name pocket-id-frontend --node-args="--env-file .env"
msg_ok "Started ${APP}"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize

#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Snarkenfaugister
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/stonith404/pocket-id

# App Default Values
APP="PocketID"
TAGS="identity-provider"
var_cpu="2"
var_ram="2048"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    if [[ ! -d /opt/pocket-id ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -fsSL https://api.github.com/repos/stonith404/pocket-id/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Updating $APP"

        msg_info "Stopping $APP"
	systemctl stop pm2-root.service
        msg_ok "Stopped $APP"

        msg_info "Creating Backup"
        tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" /opt/pocket-id
        msg_ok "Backup Created"

        msg_info "Updating $APP to v${RELEASE}"
        git fetch --tags && git checkout $(git describe --tags `git rev-list --tags --max-count=1`)
	cd /opt/pocket-id/backend/cmd
	go build -o ../pocket-id-backend
	cd ../../frontend
	npm install
	npm run build
        msg_ok "Updated $APP to v${RELEASE}"

        msg_info "Starting $APP"
	systemctl start pm2-root.service
        sleep 2
        msg_ok "Started $APP"

        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Update Successful"
    else
        msg_ok "No update required. ${APP} is already at v${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/login/setup${CL}"

#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/ball0803/script/refs/heads/master/misc/build.func)

APP="Scaffold"
var_tags="${var_tags:-rag;ai;code-analysis;python}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d "/opt/scaffold" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating Scaffold"
  pct exec "$CTID" -- bash -c "cd /opt/scaffold && git pull origin main"
  pct exec "$CTID" -- bash -c "cd /opt/scaffold && docker compose pull"
  pct exec "$CTID" -- bash -c "cd /opt/scaffold && docker compose up -d --build"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URLs:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL} (Scaffold API)"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7474${CL} (Neo4j UI - user: neo4j, pass: password)"
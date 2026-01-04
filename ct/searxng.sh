#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

APP="SearXNG"
var_tags="${var_tags:-search;privacy;metasearch;mcp}"
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

  if [[ ! -d "/usr/local/searxng" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating SearXNG"
  pct exec "$CTID" -- bash -c "cd /usr/local/searxng/searxng-src && git pull origin master"
  pct exec "$CTID" -- systemctl restart searxng
  pct exec "$CTID" -- systemctl restart mcp-searxng
  msg_ok "Updated successfully!"
  exit
}

function install_searxng() {
  msg_info "Installing SearXNG with MCP..."
  
  # Download and run the installation script
  pct exec "$CTID" -- bash -c "
    curl -fsSL https://raw.githubusercontent.com/ball0803/script/master/install/searxng-install.sh | bash
  "
  
  msg_ok "SearXNG with MCP installed successfully!"
}

start
build_container
install_searxng
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URLs:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8888${CL} (SearXNG Web Interface)"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL} (MCP SearXNG API)"

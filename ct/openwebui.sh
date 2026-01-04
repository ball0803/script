#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/ball0803/script/refs/heads/master/misc/build.func)

APP="OpenWebUI"
var_tags="${var_tags:-ai;interface}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-25}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_ollama="${var_ollama:-no}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d "/opt/openwebui" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating OpenWebUI"
  pct exec "$CTID" -- bash -c "cd /opt/openwebui && source bin/activate && pip install --upgrade open-webui"
  pct exec "$CTID" -- systemctl restart openwebui
  
  if [[ "$var_ollama" == "yes" ]]; then
    msg_info "Updating Ollama"
    pct exec "$CTID" -- bash -c "ollama pull llama3"
  fi
  
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL} (OpenWebUI)"
if [[ "$var_ollama" == "yes" ]]; then
  echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:11434${CL} (Ollama API)"
fi

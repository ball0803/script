#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
catch_errors
setting_up_container
network_check
update_os

# Use our custom build.func
source /home/camel/Desktop/Project/script/misc/build.func

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

# Custom container creation function that uses our installation script
function build_searxng_container() {
  # Build network configuration string
  NET_STRING="-net0 name=eth0,bridge=${BRG:-vmbr0}"

  # MAC
  if [[ -n "${MAC:-}" ]]; then
    case "$MAC" in
    ,hwaddr=*) NET_STRING+="$MAC" ;;
    *) NET_STRING+=",hwaddr=$MAC" ;;
    esac
  fi

  # IP (always required, default dhcp)
  NET_STRING+=",ip=${NET:-dhcp}"

  # Gateway
  if [[ -n "${GATE:-}" ]]; then
    case "$GATE" in
    ,gw=*) NET_STRING+="$GATE" ;;
    *) NET_STRING+=",gw=$GATE" ;;
    esac
  fi

  # VLAN
  if [[ -n "${VLAN:-}" ]]; then
    case "$VLAN" in
    ,tag=*) NET_STRING+="$VLAN" ;;
    *) NET_STRING+=",tag=$VLAN" ;;
    esac
  fi

  # MTU
  if [[ -n "${MTU:-}" ]]; then
    case "$MTU" in
    ,mtu=*) NET_STRING+="$MTU" ;;
    *) NET_STRING+=",mtu=$MTU" ;;
    esac
  fi

  # IPv6 Handling
  case "${IPV6_METHOD:-auto}" in
  auto) NET_STRING="$NET_STRING,ip6=auto" ;;
  dhcp) NET_STRING="$NET_STRING,ip6=dhcp" ;;
  static)
    NET_STRING="$NET_STRING,ip6=${IPV6_ADDR:-}"
    [ -n "${IPV6_GATE:-}" ] && NET_STRING="$NET_STRING,gw6=$IPV6_GATE"
    ;;
  none) ;;
  esac

  # Build FEATURES string
  FEATURES=""

  # Nesting support
  if [ "${ENABLE_NESTING:-1}" == "1" ]; then
    FEATURES="nesting=1"
  fi

  # Keyctl for unprivileged containers
  if [ "$CT_TYPE" == "1" ]; then
    [ -n "$FEATURES" ] && FEATURES="$FEATURES,"
    FEATURES="${FEATURES}keyctl=1"
  fi

  if [ "${ENABLE_FUSE:-no}" == "yes" ]; then
    [ -n "$FEATURES" ] && FEATURES="$FEATURES,"
    FEATURES="${FEATURES}fuse=1"
  fi

  # Create temporary directory for container creation
  TEMP_DIR=$(mktemp -d)
  pushd "$TEMP_DIR" >/dev/null

  # Set up environment variables for installation script
  export DIAGNOSTICS="${DIAGNOSTICS:-no}"
  export RANDOM_UUID="$RANDOM_UUID"
  export SESSION_ID="$SESSION_ID"
  export CACHER="${APT_CACHER:-}"
  export CACHER_IP="${APT_CACHER_IP:-}"
  export tz="${timezone:-UTC}"
  export APPLICATION="$APP"
  export app="$NSAPP"
  export PASSWORD="${PW:-}"
  export VERBOSE="${VERBOSE:-no}"
  export SSH_ROOT="${SSH:-no}"
  export SSH_AUTHORIZED_KEY="${SSH_AUTHORIZED_KEY:-}"
  export CTID="$CT_ID"
  export CTTYPE="$CT_TYPE"
  export ENABLE_FUSE="${ENABLE_FUSE:-no}"
  export ENABLE_TUN="${ENABLE_TUN:-no}"
  export PCT_OSTYPE="$var_os"
  export PCT_OSVERSION="$var_version"
  export PCT_DISK_SIZE="$DISK_SIZE"

  # Build PCT_OPTIONS string
  PCT_OPTIONS_STRING="  -hostname $HN
  -tags $TAGS"

  # Add features if specified
  if [ -n "$FEATURES" ]; then
    PCT_OPTIONS_STRING="  -features $FEATURES\n$PCT_OPTIONS_STRING"
  fi

  # Add DNS search domain if specified
  if [ -n "${SD:-}" ]; then
    PCT_OPTIONS_STRING="$PCT_OPTIONS_STRING\n  $SD"
  fi

  # Add nameserver if specified
  if [ -n "${NS:-}" ]; then
    PCT_OPTIONS_STRING="$PCT_OPTIONS_STRING\n  $NS"
  fi

  # Network configuration
  PCT_OPTIONS_STRING="$PCT_OPTIONS_STRING\n  $NET_STRING\n  -onboot 1\n  -cores $CORE_COUNT\n  -memory $RAM_SIZE\n  -unprivileged $CT_TYPE"

  # Protection flag
  if [ "${PROTECT_CT:-no}" == "1" ] || [ "${PROTECT_CT:-no}" == "yes" ]; then
    PCT_OPTIONS_STRING="$PCT_OPTIONS_STRING\n  -protection 1"
  fi

  # Timezone
  if [ -n "${CT_TIMEZONE:-}" ]; then
    local _pct_timezone="$CT_TIMEZONE"
    [[ "$_pct_timezone" == Etc/* ]] && _pct_timezone="host"
    PCT_OPTIONS_STRING="$PCT_OPTIONS_STRING\n  -timezone $_pct_timezone"
  fi

  # Password
  if [ -n "$PW" ]; then
    PCT_OPTIONS_STRING="$PCT_OPTIONS_STRING\n  $PW"
  fi

  export PCT_OPTIONS="$PCT_OPTIONS_STRING"

  # Create the container
  msg_info "Creating LXC container..."
  pct create "$var_template_storage" "$CT_ID" "$var_os" "$var_version" $PCT_OPTIONS
  
  if [ $? -ne 0 ]; then
    msg_error "Failed to create container"
    exit 1
  fi
  
  msg_ok "Container created successfully"

  # Start the container
  msg_info "Starting container..."
  pct start "$CT_ID"
  
  # Wait for network to come up
  msg_info "Waiting for network..."
  for i in {1..30}; do
    if pct exec "$CT_ID" -- ping -c 1 localhost >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done

  # Install base packages
  msg_info "Installing base packages..."
  pct exec "$CT_ID" -- apt update >/dev/null 2>&1
  pct exec "$CT_ID" -- apt install -y curl sudo >/dev/null 2>&1

  # Download and run our installation script
  msg_info "Running installation script..."
  pct exec "$CT_ID" -- bash -c "
    curl -fsSL https://raw.githubusercontent.com/ball0803/script/main/install/searxng-install.sh | bash
  "
  
  if [ $? -ne 0 ]; then
    msg_error "Installation failed"
    exit 1
  fi
  
  msg_ok "Installation completed successfully"

  popd >/dev/null
  rm -rf "$TEMP_DIR"
}

start
build_searxng_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URLs:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8888${CL} (SearXNG Web Interface)"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL} (MCP SearXNG API)"

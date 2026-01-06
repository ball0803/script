# AGENTS.md

## 📍 Repository Location

**Raw Files URL**: `https://raw.githubusercontent.com/ball0803/script/master/`

This is where all raw files are hosted for dynamic loading. All curl/wget commands in the scripts reference this URL.

## Project Overview
Proxmox VE Helper-Scripts - Bash automation for container/VM management

## Structure
```
./
├── ct/              # Container scripts (4 scripts)
├── install/         # Installation scripts (4 scripts)
├── misc/            # Function libraries (9 files)
└── ProxmoxVE/      # Main repository (970 files)
```

## Key Directories

- `./ct`: Container creation scripts
- `./install`: Installation scripts
- `./misc`: Function libraries
- `./ProxmoxVE`: Main repository (404 ct + 402 install scripts)

## Build/Lint/Test Commands

### Testing Scripts

```bash
# Test syntax of all container scripts
bash -n ct/*.sh

# Test syntax of all installation scripts
bash -n install/*.sh

# Test syntax of all function libraries
bash -n misc/*.func

# Test specific script syntax
bash -n ct/scaffold.sh

# Run installation test script
bash test_install.sh

# Test raw file URLs
curl -I -s -o /dev/null -w "%{http_code}" https://raw.githubusercontent.com/ball0803/script/master/misc/build.func
```

### Building and Running

```bash
# Build and run Scaffold container
bash ct/scaffold.sh

# Install Scaffold dependencies
bash install/scaffold-install.sh

# Check dependencies in installation scripts
grep -E "(apt install|docker)" install/*.sh

# Update existing Scaffold installation
bash ct/scaffold.sh --update
```

### Debugging

```bash
# Check container status
pct status 9001

# Monitor container resources
pct exec 9001 free -h
pct exec 9001 df -h

# View container logs
pct exec 9001 journalctl -u scaffold --no-pager -n 50

# Check Docker container status
pct exec 9001 docker ps -a
pct exec 9001 docker logs scaffold-app
```

## Code Style Guidelines

### General Conventions

- **No interactive prompts**: Scripts should run non-interactively
- **No hardcoded credentials**: Use environment variables or configuration files
- **2-space indent**: Consistent indentation throughout
- **Function libraries**: Place reusable functions in `misc/` directory
- **Standardized script structure**: Follow the established pattern

### Bash Scripting Standards

#### Imports and Dependencies

```bash
# Always use env bash shebang
#!/usr/bin/env bash

# Source function libraries from remote
source <(curl -fsSL https://raw.githubusercontent.com/ball0803/script/master/misc/build.func)

# Or from local if available
source /usr/local/community-scripts/default.vars
```

#### Variable Naming

- **Uppercase**: Global constants and environment variables
  ```bash
  APP="Scaffold"
  NSAPP=$(echo "${APP,,}" | tr -d ' ')
  ```

- **Lowercase with underscores**: Local variables
  ```bash
  local ct_type="1"
  local disk_size="4"
  ```

- **Prefix with var_**: Configuration variables
  ```bash
  var_cpu="2"
  var_ram="4096"
  var_disk="10"
  ```

#### Error Handling

```bash
# Use the catch_errors function from error_handler.func
catch_errors

# Check command success
if ! command; then
  msg_error "Command failed"
  exit 1
fi

# Use $STD for silent operations
$STD apt install -y package

# Use msg_* functions for output
msg_info "Installing dependencies"
msg_success "Installation completed"
msg_warn "This may take a while"
msg_error "Installation failed"
```

#### Functions

- **Function naming**: Use snake_case for function names
  ```bash
  function update_script() {
    # Function implementation
  }
  ```

- **Document functions**: Add comments explaining purpose and parameters
  ```bash
  # ------------------------------------------------------------------------------
  # function_name()
  #
  # - Description of what the function does
  # - Parameters: param1, param2
  # - Returns: description of return value
  # ------------------------------------------------------------------------------
  function_name() {
    # Implementation
  }
  ```

#### Conditionals

```bash
# Use [[ ]] for conditionals
if [[ "$var" == "value" ]]; then
  # Do something
fi

# Check if variable is set
if [[ -n "${var:-}" ]]; then
  # Variable is set
fi

# Check if variable is empty
if [[ -z "${var:-}" ]]; then
  # Variable is empty
fi
```

#### Loops

```bash
# For loops
for i in {1..3}; do
  msg_info "Attempt $i of 3"
  if command; then
    break
  fi
  sleep 5
done

# While loops
while [[ "$STEP" -le "$MAX_STEP" ]]; do
  case $STEP in
    1)
      # Step 1 logic
      ;;
    2)
      # Step 2 logic
      ;;
  esac
  ((STEP++))
done
```

#### String Manipulation

```bash
# Convert to lowercase
NSAPP=$(echo "${APP,,}" | tr -d ' ')

# Trim whitespace
line="${line#"${line%%[![:space:]]*}"}"
line="${line%"${line##*[![:space:]]}"}"

# Check regex match
if [[ "$value" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  # Valid IP address
fi
```

### Anti-Patterns

- **Hardcoded IPs, passwords**: Always use environment variables
- **Interactive user input**: Scripts should be non-interactive
- **Complex logic in scripts**: Keep scripts simple, move complex logic to functions
- **Large file operations**: Avoid operations that modify large files
- **Direct eval/source**: Use safe parsing methods instead of eval

### Best Practices

1. **Use whiptail for interactive menus**: For advanced settings
2. **Validate all user input**: Check formats and ranges
3. **Use msg_* functions**: For consistent output formatting
4. **Handle errors gracefully**: Provide meaningful error messages
5. **Test thoroughly**: Use test_install.sh pattern for validation
6. **Document dependencies**: Clearly list required packages
7. **Use environment variables**: For configuration and credentials
8. **Keep functions reusable**: Design for multiple use cases

### Testing Approach

1. **Syntax testing**: Use `bash -n script.sh` to check syntax
2. **Dependency checking**: Verify all required packages are listed
3. **URL accessibility**: Test remote file URLs before downloading
4. **Function validation**: Test individual functions in isolation
5. **Integration testing**: Test full script execution in container

### Example Script Structure

```bash
#!/usr/bin/env bash

# Source function libraries
source <(curl -fsSL https://raw.githubusercontent.com/ball0803/script/master/misc/build.func)

# Set application constants
APP="Scaffold"
var_tags="rag;ai;code-analysis;python"
var_cpu="2"
var_ram="4096"
var_disk="10"

# Initialize functions
header_info "$APP"
variables
color
catch_errors

# Main execution
start
build_container
description

# Success message
msg_ok "Completed Successfully!"
```
```

## Notes/Gotchas

- Functions sourced from community-scripts
- Docker required for most scripts
- Proxmox VE 7.x/8.x required
- Test on staging before production

## Proxmox Debugging Setup

### Environment Variables

For Proxmox debugging, create a `.env.proxmox` file in your home directory to store sensitive credentials:

```bash
# Create environment file (add to .gitignore)
mkdir -p ~/.config/proxmox
echo "PROXMOX_USER=opencode-agent" > ~/.config/proxmox/.env.proxmox
echo "PROXMOX_PASSWORD=i4}pZw;a,L5S\H$_wlYsw6>ON@7KWEtN" >> ~/.config/proxmox/.env.proxmox
echo "PROXMOX_IP=192.168.1.114" >> ~/.config/proxmox/.env.proxmox
chmod 600 ~/.config/proxmox/.env.proxmox
```

### Debugging Container Setup

1. **Create isolated debugging container:**
   ```bash
   # Create unprivileged container for debugging
   pct create 9001 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.gz \
     --hostname debug-ct \
     --cores 1 \
     --memory 1024 \
     --swap 512 \
     --unprivileged \
     --storage local-lvm
   ```

2. **Configure container security:**
   ```bash
   # Edit container config
   nano /etc/pve/lxc/9001.conf
   
   # Add these security settings:
   lxc.cgroup.devices.deny = c 5:1 rwm
   lxc.mount.entry = /dev/fuse dev/fuse none bind,optional,create=file
   lxc.cgroup.devices.allow = c 10:200 r
   lxc.apparmor.profile = unconfined
   ```

3. **Set up user permissions:**
   ```bash
   # Create custom role for debugging
   pveum role create PVEContainerDebugger
   pveum aclmod /vms/9001 -role PVEContainerDebugger -user opencode-agent
   ```

### Access and Debugging

```bash
# Access container console
pct enter 9001

# Start/Stop container
pct start 9001
pct stop 9001

# Monitor container
pct status 9001
pct exec 9001 free -h
pct exec 9001 df -h
```

### Security Best Practices

- Never commit `.env.proxmox` to version control
- Use `chmod 600` on all credential files
- Rotate passwords regularly
- Monitor container resource usage
- Isolate debugging network from production

## Proxmox API Reference

### API Endpoints for LXC Containers

The Proxmox VE API provides comprehensive endpoints for managing LXC containers:

**Container Operations:**
- `POST /nodes/{node}/lxc` - Create container
- `DELETE /nodes/{node}/lxc/{vmid}` - Delete container
- `POST /nodes/{node}/lxc/{vmid}/status/start` - Start container
- `POST /nodes/{node}/lxc/{vmid}/status/stop` - Stop container
- `POST /nodes/{node}/lxc/{vmid}/status/shutdown` - Shutdown container
- `POST /nodes/{node}/lxc/{vmid}/status/reboot` - Reboot container

**Configuration Management:**
- `GET /nodes/{node}/lxc/{vmid}/config` - Get container configuration
- `PUT /nodes/{node}/lxc/{vmid}/config` - Update container configuration
- `POST /nodes/{node}/lxc/{vmid}/config` - Apply configuration changes

**Status and Monitoring:**
- `GET /nodes/{node}/lxc/{vmid}/status/current` - Get current status and resource usage
- `GET /nodes/{node}/lxc/{vmid}/agent/network-get-interfaces` - Get network interfaces
- `GET /nodes/{node}/lxc/{vmid}/agent/disk-list` - Get disk information

**Snapshots:**
- `POST /nodes/{node}/lxc/{vmid}/snapshot` - Create snapshot
- `DELETE /nodes/{node}/lxc/{vmid}/snapshot/{snapname}` - Delete snapshot
- `POST /nodes/{node}/lxc/{vmid}/snapshot/{snapname}/rollback` - Rollback to snapshot

### Common Proxmox Commands

**View API Documentation:**
https://pve.proxmox.com/pve-docs/api-viewer/#/access/permissions

**List all containers:**
```bash
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X GET \
  https://{PROXMOX_IP}:8006/api2/json/nodes/{node}/lxc
```

**Create container:**
```bash
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X POST \
  -d '{
    "vmid": 114,
    "hostname": "test-scaffold-api",
    "ostemplate": "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst",
    "password": "password123",
    "cores": 2,
    "memory": 4096,
    "swap": 1024,
    "unprivileged": 1,
    "storage": "local-lvm"
  }' \
  https://{PROXMOX_IP}:8006/api2/json/nodes/{node}/lxc
```

**Start container:**
```bash
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X POST \
  -d '{}' \
  https://{PROXMOX_IP}:8006/api2/json/nodes/{node}/lxc/{vmid}/status/start
```

**Stop container:**
```bash
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X POST \
  -d '{}' \
  https://{PROXMOX_IP}:8006/api2/json/nodes/{node}/lxc/{vmid}/status/stop
```

**Get container status:**
```bash
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X GET \
  https://{PROXMOX_IP}:8006/api2/json/nodes/{node}/lxc/{vmid}/status/current
```

**Get container configuration:**
```bash
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X GET \
  https://{PROXMOX_IP}:8006/api2/json/nodes/{node}/lxc/{vmid}/config
```

**Delete container:**
```bash
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X DELETE \
  https://{PROXMOX_IP}:8006/api2/json/nodes/{node}/lxc/{vmid}
```

**List available storage:**
```bash
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X GET \
  https://{PROXMOX_IP}:8006/api2/json/storage
```

**List available templates:**
```bash
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X GET \
  https://{PROXMOX_IP}:8006/api2/json/nodes/{node}/storage/{storage}/content
```

**Access container console:**
```bash
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X POST \
  -d '{"command": "exec", "node": "{node}", "vmid": {vmid}, "script": "bash"}' \
  https://{PROXMOX_IP}:8006/api2/json/access/ticket
```

### API Authentication

The Proxmox API supports multiple authentication methods:

**Token Authentication (Recommended):**
```bash
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X GET \
  https://{PROXMOX_IP}:8006/api2/json/nodes
```

**Important:** The correct token format is `USER@REALM!TOKENID=UUID` where:
- `USER@REALM` is the user ID (e.g., `opencode-agent@pam`)
- `TOKENID` is the token name (e.g., `opencode-agent`)
- `UUID` is the token value (e.g., `57ec941e-77ce-4fef-9949-aa28676f017b`)

**Session Cookie:**
```bash
# First login to get session cookie
curl -k -d "username=root@pam&password={PASSWORD}" \
  https://{PROXMOX_IP}:8006/api2/json/access/ticket

# Use cookie in subsequent requests
curl -k -H "Cookie: PVEAuthCookie={COOKIE}" \
  -H "CSRFPreventionToken: {TOKEN}" \
  https://{PROXMOX_IP}:8006/api2/json/nodes
```

### Example: Create Container via API

```bash
curl -k -H "Authorization: PVEAPIToken=opencode-agent@pam!opencode-agent=57ec941e-77ce-4fef-9949-aa28676f017b" \
  -H "Content-Type: application/json" \
  -X POST \
  -d '{
    "vmid": 9001,
    "hostname": "debug-ct",
    "ostemplate": "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.gz",
    "password": "debug123",
    "cores": 1,
    "memory": 1024,
    "swap": 512,
    "unprivileged": 1,
    "storage": "local-lvm"
  }' \
  https://192.168.1.114:8006/api2/json/nodes/camel/lxc
```

**Note:** Replace `camel` with your actual Proxmox node name. To find your node name, use:
```bash
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X GET \
  https://{PROXMOX_IP}:8006/api2/json/nodes
```

### Troubleshooting API Issues

**Common Issues:**

1. **Authentication Failure**: Ensure the token format is correct: `USER@REALM!TOKENID=UUID`
2. **Permission Denied**: The token may not have sufficient privileges. Check with `pveum user token list USER@REALM`
3. **Node Not Found**: Verify the node name exists using the nodes API endpoint
4. **Timeout Issues**: Check network connectivity and firewall settings

**Debugging Commands:**

```bash
# Check API version (basic connectivity test)
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X GET \
  https://{PROXMOX_IP}:8006/api2/json/version

# List all nodes
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X GET \
  https://{PROXMOX_IP}:8006/api2/json/nodes

# List all containers on a node
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X GET \
  https://{PROXMOX_IP}:8006/api2/json/nodes/{node}/lxc

# Check container status
curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=UUID" \
  -H "Content-Type: application/json" \
  -X GET \
  https://{PROXMOX_IP}:8006/api2/json/nodes/{node}/lxc/{vmid}/status/current
```

### API Documentation

Full API documentation is available at:
https://pve.proxmox.com/pve-docs/api-viewer/index.html#/nodes/{node}/lxc

For interactive API exploration, use the Proxmox web interface at:
https://{PROXMOX_IP}:8006/api2/view/nodes/{node}/lxc

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

## Conventions

- No interactive prompts
- No hardcoded credentials
- 2-space indent
- Function libraries in misc/
- Standardized script structure

## Anti-Patterns

- Hardcoded IPs, passwords
- Interactive user input
- Complex logic in scripts
- Large file operations

## Commands

```bash
# Build container
bash ct/scaffold.sh

# Install dependencies
bash install/scaffold-install.sh

# Test syntax
bash -n ct/*.sh

# Check dependencies
grep -E "(apt install|docker)" install/*.sh

# Test raw file URLs
echo "Testing raw URL access:"
curl -I -s -o /dev/null -w "%{http_code}" https://raw.githubusercontent.com/ball0803/script/master/misc/build.func
echo ""
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
- `PUT /nodes/{node}/lxc/{vmid}/status/start` - Start container
- `PUT /nodes/{node}/lxc/{vmid}/status/stop` - Stop container
- `PUT /nodes/{node}/lxc/{vmid}/status/shutdown` - Shutdown container
- `PUT /nodes/{node}/lxc/{vmid}/status/reboot` - Reboot container

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

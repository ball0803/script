# SearXNG Container Creation Script

## Overview

This script creates a Proxmox VE LXC container optimized for SearXNG with MCP integration.

## Features

- **Automatic Container Creation**: Creates a Debian 12 LXC container with proper resource allocation
- **Network Configuration**: Supports IPv4, IPv6, VLAN, and MTU settings
- **MCP Integration**: Includes Node.js 20.x and MCP SearXNG server
- **Resource Management**: Configurable CPU, RAM, and disk allocation
- **Security**: Firewall configuration and secure defaults
- **Service Management**: Systemd services for easy management

## Usage

### Basic Installation

```bash
# Quick install with default settings
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ball0803/script/master/ct/searxng.sh)"

# Or clone and run locally
git clone https://github.com/ball0803/script.git
cd script
bash ct/searxng.sh
```

### Custom Resource Allocation

```bash
# High-performance configuration
VAR_CPU=4 VAR_RAM=8192 VAR_DISK=20 bash ct/searxng.sh

# Minimum configuration (for testing)
VAR_CPU=2 VAR_RAM=4096 VAR_DISK=10 bash ct/searxng.sh
```

### Advanced Configuration

```bash
# Custom network settings
VAR_NET=192.168.1.100/24 VAR_GATEWAY=192.168.1.1 bash ct/searxng.sh

# IPv6 configuration
VAR_IPV6_METHOD=auto bash ct/searxng.sh

# VLAN tagging
VAR_VLAN=100 bash ct/searxng.sh

# Custom MTU
VAR_MTU=1500 bash ct/searxng.sh
```

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `VAR_CPU` | Number of CPU cores | 2 |
| `VAR_RAM` | RAM in MB | 4096 |
| `VAR_DISK` | Disk size in GB | 10 |
| `VAR_OS` | Operating system | debian |
| `VAR_VERSION` | OS version | 12 |
| `VAR_NET` | IP address | dhcp |
| `VAR_GATEWAY` | Gateway IP | auto |
| `VAR_VLAN` | VLAN tag | (none) |
| `VAR_MTU` | MTU size | (auto) |
| `VAR_IPV6_METHOD` | IPv6 method | auto |

## Services

After installation, the following services will be available:

- **SearXNG Web Interface**: `http://<CONTAINER_IP>:8888`
- **MCP SearXNG API**: `http://<CONTAINER_IP>:3000`
- **Redis Cache**: Port 6379

## Update Functionality

```bash
# Update existing installation
bash ct/searxng.sh --update
```

## Technical Details

### Container Specifications

- **Base OS**: Debian 12
- **Architecture**: amd64
- **Type**: Privileged (for full functionality)
- **Features**: Nesting, FUSE, TUN support

### Software Stack

- **SearXNG**: Latest version from source
- **Node.js**: 20.x (for MCP support)
- **MCP SearXNG**: Official MCP server
- **Redis**: Caching backend
- **Nginx**: Reverse proxy
- **UFW**: Firewall management

### Network Configuration

- **Web Interface**: Port 8888
- **MCP API**: Port 3000
- **Redis**: Port 6379 (localhost only)
- **SearXNG Backend**: Port 8886 (localhost only)

## Troubleshooting

### Common Issues

**Container creation failed**
- Check Proxmox VE has enough resources
- Verify storage pool is available
- Check network bridge configuration

**Installation failed**
- Check container has network access
- Verify apt sources are working
- Check disk space in container

**Services not starting**
- Check logs: `journalctl -u searxng -f`
- Check logs: `journalctl -u mcp-searxng -f`
- Check logs: `journalctl -u redis -f`

**Port conflicts**
- Check for other services using ports 8888 or 3000
- Modify Nginx configuration if needed

### Debugging

```bash
# Check container status
pct status <CTID>

# Enter container
pct enter <CTID>

# Check service status
systemctl status searxng
systemctl status mcp-searxng
systemctl status redis

# Check Nginx configuration
nginx -t

# Check firewall status
ufw status
```

## Requirements

- **Proxmox VE**: 7.x or 8.x
- **CPU**: 2+ cores
- **RAM**: 4GB+ recommended
- **Disk**: 10GB+ recommended
- **Network**: Internet access for container

## Best Practices

1. **Resource Allocation**: Allocate at least 4GB RAM for production use
2. **Backup**: Regularly backup the container
3. **Updates**: Keep SearXNG updated for security
4. **Monitoring**: Monitor resource usage and service health
5. **Security**: Keep firewall enabled and updated

## Support

For issues and questions, please refer to:
- [SearXNG Documentation](https://docs.searxng.org/)
- [MCP SearXNG Documentation](https://github.com/mcp-searxng/mcp-searxng)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)

## License

This script is part of the script repository and is licensed under the GPL-3.0 license.

# SearXNG Container Creation Script

## Quick Install

To install SearXNG with MCP integration using a single command:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ball0803/script/master/ct/searxng.sh)"
```

## Overview

This script creates a Proxmox VE LXC container optimized for running SearXNG, a privacy-respecting metasearch engine, with MCP (Model Context Protocol) integration.

## Features

- **Automated Container Creation**: Uses the community-scripts build.func framework
- **Resource Management**: Configurable CPU, RAM, and disk allocation
- **Privileged Mode**: Required for proper service management
- **Update Functionality**: Built-in update mechanism for existing installations
- **MCP Integration**: Includes MCP SearXNG server for AI agent integration
- **Access Information**: Displays URLs for SearXNG web interface and MCP API

## Usage

### Basic Installation

```bash
bash ct/searxng.sh
```

### Custom Resource Allocation

```bash
# High-performance configuration
VAR_CPU=4 VAR_RAM=8192 VAR_DISK=20 bash ct/searxng.sh

# Minimum configuration (for testing)
VAR_CPU=2 VAR_RAM=4096 VAR_DISK=10 bash ct/searxng.sh
```

### Update Existing Installation

```bash
bash ct/searxng.sh --update
```

## Configuration Variables

| Variable | Description | Default | Recommended Minimum |
|----------|-------------|---------|---------------------|
| `var_cpu` | Number of CPU cores | 2 | 2 |
| `var_ram` | RAM in MB | 4096 | 4096 |
| `var_disk` | Disk size in GB | 10 | 10 |
| `var_os` | Operating system | debian | debian |
| `var_version` | OS version | 12 | 12 |
| `var_unprivileged` | Privileged mode (0=privileged) | 0 | 0 |
| `var_tags` | Container tags | search;privacy;metasearch;mcp | - |

## Services and Ports

After installation, the following services will be available:

| Service | Port | Description |
|---------|------|-------------|
| SearXNG Web | 8888 | SearXNG web interface |
| MCP SearXNG | 3000 | MCP API for AI integration |
| Valkey (Redis) | 6379 | Cache database |

## Requirements

- **Proxmox VE** 7.x or 8.x
- **LXC Container Support**
- **Internet Connection** for package downloads
- **Available Resources**: 2+ CPU cores, 4GB+ RAM, 10GB+ disk

## Output

After successful installation, the script displays:
- SearXNG Web URL: `http://<CONTAINER_IP>:8888`
- MCP SearXNG API URL: `http://<CONTAINER_IP>:3000`

## Troubleshooting

### Common Issues

1. **Insufficient Resources**: Increase CPU/RAM allocation if services fail to start
2. **Port Conflicts**: Ensure ports 8888, 3000, 6379 are available
3. **Network Issues**: Verify container has network connectivity
4. **Permission Errors**: Container must be created in privileged mode

### Debugging

```bash
# Enable verbose mode
VAR_VERBOSE=yes bash ct/searxng.sh

# Check container status
pct list | grep searxng

# Enter container
pct enter <CTID>

# Check service status
systemctl status searxng
systemctl status mcp-searxng

# View logs
journalctl -u searxng -f
journalctl -u mcp-searxng -f
```

## MCP Configuration

To use SearXNG with MCP-compatible clients (like Cursor IDE):

```json
{
  "mcpServers": {
    "searxng-mcp": {
      "url": "http://<CONTAINER_IP>:3000"
    }
  }
}
```

## See Also

- [SearXNG Installation Script README](../install/README_searxng.md)
- [SearXNG Documentation](https://docs.searxng.org/)
- [MCP SearXNG Documentation](https://github.com/artificialintelligence-news/mcp-searxng)
- [Community Scripts Documentation](https://github.com/community-scripts/ProxmoxVE)

# Scaffold Container Creation Script

## Overview

This script creates a Proxmox VE LXC container optimized for running Scaffold, a Structural RAG system for code analysis.

## Features

- **Automated Container Creation**: Uses the community-scripts build.func framework
- **Resource Management**: Configurable CPU, RAM, and disk allocation
- **Privileged Mode**: Required for Docker-in-Docker support
- **Update Functionality**: Built-in update mechanism for existing installations
- **Access Information**: Displays URLs for Scaffold API and Neo4j UI after installation

## Usage

### Basic Installation

```bash
bash ct/scaffold.sh
```

### Custom Resource Allocation

```bash
# High-performance configuration
VAR_CPU=4 VAR_RAM=8192 VAR_DISK=20 bash ct/scaffold.sh

# Minimum configuration (for testing)
VAR_CPU=2 VAR_RAM=4096 VAR_DISK=10 bash ct/scaffold.sh
```

### Update Existing Installation

```bash
bash ct/scaffold.sh --update
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
| `var_tags` | Container tags | rag;ai;code-analysis;python | - |

## Requirements

- **Proxmox VE** 7.x or 8.x
- **LXC Container Support**
- **Internet Connection** for package downloads
- **Available Resources**: 2+ CPU cores, 4GB+ RAM, 10GB+ disk

## Output

After successful installation, the script displays:
- Scaffold API URL: `http://<CONTAINER_IP>:8000`
- Neo4j UI URL: `http://<CONTAINER_IP>:7474` (user: neo4j, password: password)

## Troubleshooting

### Common Issues

1. **Insufficient Resources**: Increase CPU/RAM allocation if services fail to start
2. **Port Conflicts**: Ensure ports 8000, 7474, 7687 are available
3. **Network Issues**: Verify container has network connectivity
4. **Permission Errors**: Container must be created in privileged mode

### Debugging

```bash
# Enable verbose mode
VAR_VERBOSE=yes bash ct/scaffold.sh

# Check container status
pct list | grep scaffold

# Enter container
pct enter <CTID>
```

## See Also

- [Scaffold Installation Script README](../install/README.md)
- [Community Scripts Documentation](https://github.com/community-scripts/ProxmoxVE)
- [Scaffold Documentation](https://github.com/Beer-Bears/scaffold)

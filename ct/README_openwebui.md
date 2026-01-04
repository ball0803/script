# OpenWebUI Container Creation Script

## Overview

This script creates a Proxmox VE LXC container optimized for OpenWebUI with optional Ollama integration.

## Features

- **Automatic Container Creation**: Creates a Debian 13 LXC container with proper resource allocation
- **Resource Configuration**: Configurable CPU, RAM, and disk allocation
- **Optional Ollama Integration**: Enable Ollama for local LLM serving
- **Network Configuration**: Supports IPv4, IPv6, VLAN, and MTU settings
- **Persistence**: Data stored in container's filesystem
- **No Security**: Simple, straightforward installation as requested

## Usage

### Basic Installation

```bash
# Quick install with default settings
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ball0803/script/master/ct/openwebui.sh)"
```

### Custom Resource Allocation

```bash
# High-performance configuration
VAR_CPU=6 VAR_RAM=16384 VAR_DISK=50 bash ct/openwebui.sh

# Minimum configuration
VAR_CPU=4 VAR_RAM=8192 VAR_DISK=25 bash ct/openwebui.sh
```

### With Ollama Integration

```bash
VAR_OLLAMA=yes bash ct/openwebui.sh
```

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `VAR_CPU` | Number of CPU cores | 4 |
| `VAR_RAM` | RAM in MB | 8192 |
| `VAR_DISK` | Disk size in GB | 25 |
| `VAR_OS` | Operating system | debian |
| `VAR_VERSION` | OS version | 13 |
| `VAR_OLLAMA` | Install Ollama | no |

## Services After Installation

- **OpenWebUI Web Interface**: `http://<CONTAINER_IP>:3000`
- **Ollama API** (if enabled): `http://<CONTAINER_IP>:11434`

## Configuration Options

### OpenAI API Compatibility

OpenWebUI supports OpenAI API compatible services (like self-hosted vLLM). Configure this in the OpenWebUI web interface:

1. Access OpenWebUI at `http://<CONTAINER_IP>:3000`
2. Navigate to Settings
3. Configure your OpenAI API compatible endpoint

### Ollama Integration

To enable Ollama, use the `VAR_OLLAMA=yes` parameter during installation. This will:

- Install Ollama service
- Pull the default `llama3` model
- Make Ollama available at port 11434

## Technical Details

### Software Stack

- **Base OS**: Debian 13
- **Python**: 3.11+
- **OpenWebUI**: Latest version from PyPI
- **Ollama** (optional): Latest version
- **Nginx**: Reverse proxy
- **UFW**: Firewall management

### Data Persistence

- OpenWebUI data: `/opt/openwebui/data`
- Ollama data (if enabled): `/root/.ollama`
- No automated backup functionality (as requested)

## Troubleshooting

### Common Issues

**Container creation failed**
- Check Proxmox VE has enough resources
- Verify storage pool is available
- Check network bridge configuration

**OpenWebUI not starting**
- Check logs: `journalctl -u openwebui -f`
- Verify Python dependencies are installed
- Check port 3000 is available

**Ollama not working**
- Check logs: `journalctl -u ollama -f`
- Verify port 11434 is available
- Check model download completed

### Debugging Commands

```bash
# Check container status
pct status <CTID>

# Enter container
pct enter <CTID>

# Check service status
systemctl status openwebui
systemctl status ollama

# Check Nginx configuration
nginx -t

# Check firewall status
ufw status
```

## Requirements

- **Proxmox VE**: 7.x or 8.x
- **CPU**: 4+ cores
- **RAM**: 8GB+ recommended
- **Disk**: 25GB+ recommended
- **Network**: Internet access for container

## Best Practices

1. **Resource Allocation**: Allocate at least 8GB RAM for production use
2. **Monitoring**: Monitor resource usage and service health
3. **Updates**: Keep OpenWebUI updated for new features
4. **Data Backup**: Manually backup important data as needed

## Support

For issues and questions, please refer to:
- [OpenWebUI Documentation](https://docs.openwebui.com/)
- [Ollama Documentation](https://ollama.com/documentation)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)

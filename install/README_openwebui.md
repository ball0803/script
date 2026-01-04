# OpenWebUI Installation Script

## Overview

This script installs and configures OpenWebUI inside a Proxmox VE LXC container. It uses pip installation instead of Docker for simplicity and easier maintenance.

## Installation Process

The installation script performs the following steps:

1. **Install System Dependencies**: Python, pip, nginx, ufw, and build tools
2. **Create Python Virtual Environment**: Isolated Python environment for OpenWebUI
3. **Install OpenWebUI**: Using pip from PyPI
4. **Configure Systemd Service**: For automatic startup and management
5. **Optional Ollama Installation**: If enabled via `VAR_OLLAMA=yes`
6. **Configure Nginx**: Reverse proxy for web interface
7. **Configure Firewall**: Open necessary ports
8. **Start Services**: Enable and start all services

## Configuration

### Environment Variables

The installation script supports the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `VAR_OLLAMA` | Install Ollama | no |

### OpenWebUI Configuration

OpenWebUI is configured to:
- Listen on port 8080 (internal)
- Expose via Nginx on port 3000
- Use persistence storage at `/opt/openwebui/data`
- Support OpenAI API compatible services

### Ollama Configuration (if enabled)

When `VAR_OLLAMA=yes`:
- Ollama installed and enabled
- Default model `llama3` pulled
- Listens on port 11434
- Data stored at `/root/.ollama`

## Usage

### After Installation

1. **Access Web Interface**: `http://<CONTAINER_IP>:3000`
2. **Configure OpenAI API**: Navigate to Settings in OpenWebUI
3. **Add Models**: Use the web interface to add models

### Managing Services

```bash
# Start all services
systemctl start openwebui
systemctl start ollama  # if enabled

# Stop all services
systemctl stop openwebui
systemctl stop ollama  # if enabled

# Restart all services
systemctl restart openwebui
systemctl restart ollama  # if enabled

# Check service status
systemctl status openwebui
systemctl status ollama  # if enabled

# Enable services on boot
systemctl enable openwebui
systemctl enable ollama  # if enabled
```

### Viewing Logs

```bash
# OpenWebUI logs
journalctl -u openwebui -f

# Ollama logs (if enabled)
journalctl -u ollama -f

# Nginx logs
tail -f /var/log/nginx/error.log
```

## Configuration Files

### OpenWebUI Service

- **Location**: `/etc/systemd/system/openwebui.service`
- **Configuration**: Standard systemd service

### Nginx Configuration

- **Location**: `/etc/nginx/sites-available/openwebui`
- **Enabled**: Symlinked to `/etc/nginx/sites-enabled/`
- **Test**: `nginx -t` before reloading

### Firewall Configuration

- **Location**: `/etc/ufw/applications.d/`
- **Status**: `ufw status`
- **Management**: `ufw allow/deny` commands

## OpenAI API Configuration

OpenWebUI supports OpenAI API compatible services (like self-hosted vLLM). Configure this in the web interface:

1. Access OpenWebUI at `http://<CONTAINER_IP>:3000`
2. Navigate to **Settings** > **API Keys**
3. Add your OpenAI API compatible endpoint
4. Configure the base URL and API key

### Example Configuration

- **Base URL**: `http://your-vllm-server:8000/v1`
- **API Key**: `your-api-key`

## Ollama Integration

### Using Ollama Models

1. **Access OpenWebUI**: `http://<CONTAINER_IP>:3000`
2. **Navigate to Models**: Click on the models section
3. **Add Ollama Model**: Select from available models
4. **Configure Connection**: Use `http://localhost:11434` as the Ollama URL

### Managing Ollama

```bash
# Pull additional models
ollama pull llama2
ollama pull mistral

# List available models
ollama list

# Run Ollama shell
ollama
```

## Troubleshooting

### Common Issues

#### Service Fails to Start

```bash
# Check logs
journalctl -u openwebui -f

# Check dependencies
python3 -m venv /opt/openwebui/test && source /opt/openwebui/test/bin/activate && pip install open-webui
```

#### Port Already in Use

```bash
# Check listening ports
ss -tulnp | grep 3000
ss -tulnp | grep 8080

# Find conflicting process
lsof -i :3000
lsof -i :8080
```

#### Nginx Configuration Error

```bash
# Test configuration
nginx -t

# Check error logs
tail -f /var/log/nginx/error.log

# Reload Nginx
systemctl reload nginx
```

### Debugging Commands

```bash
# Check Python environment
python3 -m pip list

# Check OpenWebUI installation
ls -la /opt/openwebui/

# Check Nginx configuration
nginx -t

# Check network connectivity
ping google.com
curl -v http://localhost:8080
```

## Customization

### Adding Models

OpenWebUI supports multiple ways to add models:

1. **Ollama Models**: Configure Ollama connection in Settings
2. **OpenAI API**: Add your OpenAI API compatible endpoint
3. **Local Models**: Use the model library in the web interface

### Changing Ports

1. Edit `/etc/nginx/sites-available/openwebui`
2. Update port numbers
3. Test configuration: `nginx -t`
4. Reload Nginx: `systemctl reload nginx`
5. Update firewall: `ufw allow NEW_PORT`

## Data Persistence

### Data Locations

- **OpenWebUI Data**: `/opt/openwebui/data`
- **Ollama Data** (if enabled): `/root/.ollama`
- **Configuration**: `/etc/systemd/system/openwebui.service`

### Manual Backup

```bash
# Backup OpenWebUI data
tar -czvf openwebui-backup.tar.gz /opt/openwebui/data

# Backup Ollama data (if enabled)
tar -czvf ollama-backup.tar.gz /root/.ollama
```

## Requirements

### System Requirements

- **CPU**: 4+ cores
- **RAM**: 8GB+ recommended
- **Disk**: 25GB+ recommended
- **OS**: Debian 13

### Software Dependencies

- **Python**: 3.11+
- **pip**: Latest version
- **nginx**: Latest version
- **UFW**: Firewall management

## Support

### Official Documentation

- [OpenWebUI Documentation](https://docs.openwebui.com/)
- [Ollama Documentation](https://ollama.com/documentation)
- [Python Documentation](https://docs.python.org/3/)
- [Nginx Documentation](https://nginx.org/en/docs/)

### Community Resources

- [OpenWebUI GitHub Issues](https://github.com/open-webui/open-webui/issues)
- [Ollama Community](https://community.ollama.com/)
- [Proxmox VE Forum](https://forum.proxmox.com/)

## License

This script is part of the script repository and is licensed under the GPL-3.0 license.

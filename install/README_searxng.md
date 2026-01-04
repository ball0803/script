# SearXNG Installation Script with MCP Integration

## Quick Install

To install SearXNG with MCP integration using a single command:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ball0803/script/master/ct/searxng.sh)"
```

## Overview

This script installs and configures SearXNG with MCP integration within a Proxmox VE LXC container. It handles all dependencies, service configuration, and system setup required for a complete SearXNG deployment with AI agent integration.

## Features

- **Automated Dependency Installation**: Installs all required system packages
- **Node.js Installation**: Sets up Node.js 20.x for MCP support
- **MCP SearXNG**: Installs and configures MCP SearXNG server
- **SearXNG Setup**: Clones and builds SearXNG from source
- **Service Management**: Creates systemd services for easy management
- **Environment Configuration**: Sets up proper configuration files
- **Security**: Configures proper permissions and security settings

## Installation Process

The script performs the following steps:

1. **System Update**: Updates all packages to latest versions
2. **Dependency Installation**: Installs Python, Node.js, build tools, and Valkey (Redis)
3. **MCP Setup**: Installs MCP SearXNG globally via npm
4. **User Setup**: Creates dedicated searxng user
5. **SearXNG Clone**: Clones SearXNG repository from GitHub
6. **Python Environment**: Creates virtual environment and installs dependencies
7. **Configuration**: Sets up SearXNG settings with secure defaults
8. **Systemd Services**: Creates services for SearXNG and MCP SearXNG
9. **Service Activation**: Enables and starts all services
10. **Cleanup**: Removes temporary files and customizes container

## Services

After installation, the following services will be running:

| Service | Port | Description |
|---------|------|-------------|
| SearXNG Web | 8888 | SearXNG web interface |
| MCP SearXNG | 3000 | MCP API for AI integration |
| Valkey (Redis) | 6379 | Cache database |

## Management

### Starting/Stopping Services

```bash
# Start all services
systemctl start searxng mcp-searxng

# Stop all services
systemctl stop searxng mcp-searxng

# Restart services
systemctl restart searxng mcp-searxng

# Check status
systemctl status searxng
systemctl status mcp-searxng

# View logs
journalctl -u searxng -f
journalctl -u mcp-searxng -f
```

### Configuration Files

- **Main Configuration**: `/etc/searxng/settings.yml`
- **Systemd Services**: `/etc/systemd/system/searxng.service` and `/etc/systemd/system/mcp-searxng.service`
- **SearXNG Source**: `/usr/local/searxng/searxng-src/`
- **Python Environment**: `/usr/local/searxng/searx-pyenv/`

## Customization

### Editing SearXNG Settings

```bash
# Edit the main configuration
nano /etc/searxng/settings.yml

# Restart SearXNG after changes
systemctl restart searxng
```

### Adding Search Engines

Edit `/etc/searxng/settings.yml` and add more engines to the `engines` section:

```yaml
engines:
  - name: google
    engine: google
    shortcut: gg
  - name: duckduckgo
    engine: duckduckgo
    shortcut: ddg
  - name: wikipedia
    engine: wikipedia
    shortcut: wp
  # Add more engines here
```

### MCP Configuration

The MCP SearXNG server is configured with:
- **SearXNG URL**: `http://127.0.0.1:8888`
- **MCP Port**: `3000`

To customize MCP settings, edit the systemd service file:

```bash
nano /etc/systemd/system/mcp-searxng.service
```

Then reload and restart the service:

```bash
systemctl daemon-reload
systemctl restart mcp-searxng
```

## MCP Integration

### Using with MCP Clients

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

### Available MCP Tools

The MCP SearXNG server provides:
- **Web Search**: Perform searches across multiple engines
- **Image Search**: Find images from various sources
- **Video Search**: Search for videos
- **News Search**: Get news results

## Requirements

### System Requirements

- **CPU**: 2+ cores (4+ recommended)
- **RAM**: 4GB+ (8GB+ recommended)
- **Disk**: 10GB+ (SSD recommended)
- **Network**: Internet access for initial setup

### Software Dependencies

- Python 3.10+
- Node.js 20.x
- Git
- Build tools (gcc, python3-dev, etc.)
- Valkey (Redis)
- uWSGI

## Troubleshooting

### Common Issues

#### 1. Node.js Installation Failures

**Symptoms**: Node.js installation fails or npm permission errors

**Solution**:
```bash
# Manually install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Fix npm permissions
npm install -g -f mcp-searxng
```

#### 2. Python Environment Issues

**Symptoms**: Python virtual environment fails to create

**Solution**:
```bash
# Check Python version
python3 --version

# Manually create virtual environment
sudo -H -u searxng python3 -m venv /usr/local/searxng/searx-pyenv
```

#### 3. Port Conflicts

**Symptoms**: Services fail to start, port already in use

**Solution**:
```bash
# Check which process is using the port
netstat -tulnp | grep <PORT>

# Stop conflicting services
systemctl stop <conflicting-service>
```

#### 4. SearXNG Configuration Errors

**Symptoms**: SearXNG fails to start with configuration errors

**Solution**:
```bash
# Check the configuration file
nano /etc/searxng/settings.yml

# Test SearXNG manually
sudo -H -u searxng /usr/local/searxng/searx-pyenv/bin/python -m searx.webapp
```

#### 5. MCP Service Issues

**Symptoms**: MCP SearXNG service fails to start

**Solution**:
```bash
# Check service status
systemctl status mcp-searxng

# View logs
journalctl -u mcp-searxng -f

# Test MCP manually
mcp-searxng
```

### Debugging

```bash
# Enable verbose logging
export VAR_VERBOSE=yes

# Check system logs
journalctl -xe

# Check Docker logs (if applicable)
docker logs -f searxng

# Test network connectivity
ping localhost
curl -v http://localhost:8888
curl -v http://localhost:3000
```

## Security

### Changing Default Settings

```bash
# Edit the configuration file
nano /etc/searxng/settings.yml

# Change the secret key
SECRET_KEY=$(openssl rand -hex 32)

# Restart services
systemctl restart searxng
```

### Securing the Web Interface

Add authentication to Nginx or use SearXNG's built-in authentication:

```yaml
# In /etc/searxng/settings.yml
ui:
  static_use_hash: true
auth:
  enabled: true
  # Configure authentication method
```

### Firewall Configuration

```bash
# On Proxmox host, allow required ports
iptables -A INPUT -p tcp --dport 8888 -j ACCEPT
iptables -A INPUT -p tcp --dport 3000 -j ACCEPT
iptables -A INPUT -p tcp --dport 6379 -j ACCEPT
```

## Performance Optimization

### Resource Tuning

```bash
# Adjust systemd service resource limits
cat > /etc/systemd/system/searxng.service << 'EOF'
[Unit]
Description=SearXNG service
After=network.target valkey-server.service
Wants=valkey-server.service

[Service]
Type=simple
User=searxng
Group=searxng
Environment="SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml"
ExecStart=/usr/local/searxng/searx-pyenv/bin/python -m searx.webapp
WorkingDirectory=/usr/local/searxng/searxng-src
Restart=always
# Add resource limits here

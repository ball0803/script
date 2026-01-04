# SearXNG Installation Script

## Overview

This script installs and configures SearXNG with MCP integration inside a Proxmox VE LXC container.

## Installation Process

The installation script performs the following steps:

1. **Add Backports Repository**: For access to newer packages
2. **Update Package Lists**: Ensure all packages are up-to-date
3. **Install System Dependencies**: Python, Node.js, Redis, Nginx, and other requirements
4. **Install Node.js 20.x**: For MCP support
5. **Install MCP SearXNG**: Official MCP server for SearXNG
6. **Clone SearXNG Source**: Latest version from GitHub
7. **Install Python Dependencies**: All requirements for SearXNG
8. **Configure SearXNG**: Set ports, bindings, and Redis caching
9. **Create Systemd Services**: For SearXNG, MCP SearXNG, and Redis
10. **Configure Nginx**: Reverse proxy for web interface and MCP API
11. **Configure Firewall**: Open necessary ports
12. **Start Services**: Enable and start all services

## Configuration

### SearXNG Settings

- **Port**: 8886 (backend)
- **Web Interface**: 8888 (via Nginx)
- **Bind Address**: 0.0.0.0 (accessible from container)
- **Cache**: Redis on localhost:6379

### MCP SearXNG Settings

- **Port**: 3000
- **Bind Address**: 0.0.0.0 (accessible from container)
- **Installation**: Global npm package

### Redis Settings

- **Port**: 6379
- **Bind Address**: 127.0.0.1 (localhost only)
- **Database**: 0

### Nginx Configuration

- **Web Interface**: Port 8888
- **MCP API**: Port 3000 (under /mcp path)
- **Proxy Headers**: Properly set for SearXNG

### Firewall Rules

- **Allowed**: TCP ports 8888 and 3000
- **Enabled**: UFW firewall

## Services

### Systemd Services

#### searxng.service

```ini
[Unit]
Description=SearXNG Metasearch Engine
After=network.target redis.service

[Service]
User=root
Group=root
WorkingDirectory=/usr/local/searxng/searxng-src
Environment="PYTHONUNBUFFERED=1"
ExecStart=/usr/bin/python3 /usr/local/searxng/searxng-src/searx/webapp.py
Restart=always

[Install]
WantedBy=multi-user.target
```

#### mcp-searxng.service

```ini
[Unit]
Description=MCP SearXNG Server
After=network.target

[Service]
User=root
Group=root
ExecStart=/usr/bin/node /usr/local/lib/node_modules/@mcp/searxng/dist/index.js
Restart=always

[Install]
WantedBy=multi-user.target
```

#### redis.service

Standard Redis service with default configuration.

### Nginx Configuration

```nginx
server {
    listen 8888;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8886;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /mcp {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Usage

### After Installation

1. **Access Web Interface**: `http://<CONTAINER_IP>:8888`
2. **Access MCP API**: `http://<CONTAINER_IP>:3000`
3. **Configure SearXNG**: Visit web interface and configure search engines

### Managing Services

```bash
# Start all services
systemctl start searxng mcp-searxng redis

# Stop all services
systemctl stop searxng mcp-searxng redis

# Restart all services
systemctl restart searxng mcp-searxng redis

# Check service status
systemctl status searxng
systemctl status mcp-searxng
systemctl status redis

# Enable services on boot
systemctl enable searxng mcp-searxng redis
```

### Viewing Logs

```bash
# SearXNG logs
journalctl -u searxng -f

# MCP SearXNG logs
journalctl -u mcp-searxng -f

# Redis logs
journalctl -u redis -f

# Nginx logs
tail -f /var/log/nginx/error.log
```

## Configuration Files

### SearXNG Configuration

- **Location**: `/usr/local/searxng/searxng-src/settings.yml`
- **Backup**: `settings.yml.bak` (created during installation)
- **Customization**: Edit `settings.yml` and restart service

### Nginx Configuration

- **Location**: `/etc/nginx/sites-available/searxng`
- **Enabled**: Symlinked to `/etc/nginx/sites-enabled/`
- **Test**: `nginx -t` before reloading

### Firewall Configuration

- **Location**: `/etc/ufw/applications.d/`
- **Status**: `ufw status`
- **Management**: `ufw allow/deny` commands

## Troubleshooting

### Common Issues

#### Service Fails to Start

```bash
# Check logs
journalctl -u searxng -f

# Check dependencies
systemctl status redis

# Check configuration
nginx -t
```

#### Port Already in Use

```bash
# Check listening ports
ss -tulnp | grep 8888
ss -tulnp | grep 3000

# Find conflicting process
lsof -i :8888
lsof -i :3000
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

#### Redis Connection Issues

```bash
# Check Redis status
systemctl status redis

# Test Redis connection
redis-cli ping

# Check Redis logs
journalctl -u redis -f
```

### Debugging Commands

```bash
# Check Python environment
python3 -m pip list

# Check Node.js environment
node -v
npm -v

# Check SearXNG installation
ls -la /usr/local/searxng/searxng-src/

# Check MCP installation
npm list -g --depth=0

# Check network connectivity
ping google.com
curl -v http://localhost:8886
curl -v http://localhost:3000
```

## Customization

### Adding Search Engines

Edit `/usr/local/searxng/searxng-src/settings.yml` and add engines under the `engines` section.

### Changing Ports

1. Edit `/etc/nginx/sites-available/searxng`
2. Update port numbers
3. Test configuration: `nginx -t`
4. Reload Nginx: `systemctl reload nginx`
5. Update firewall: `ufw allow NEW_PORT`

### Customizing SearXNG

Refer to the [SearXNG documentation](https://docs.searxng.org/) for advanced configuration options.

## Security

### Firewall

- UFW is enabled by default
- Only ports 8888 and 3000 are open
- Redis is bound to localhost only

### Updates

```bash
# Update SearXNG
cd /usr/local/searxng/searxng-src
git pull origin master
python3 -m pip install -r requirements.txt
systemctl restart searxng

# Update MCP SearXNG
npm update -g @mcp/searxng
systemctl restart mcp-searxng

# Update system packages
apt update && apt upgrade -y
```

### Best Practices

1. **Regular Updates**: Keep all software updated
2. **Backup Configuration**: Regularly backup `settings.yml`
3. **Monitor Logs**: Watch for suspicious activity
4. **Limit Access**: Use firewall to restrict IP ranges if needed
5. **Secure SearXNG**: Configure proper settings in `settings.yml`

## Requirements

### System Requirements

- **CPU**: 2+ cores
- **RAM**: 4GB+ recommended
- **Disk**: 10GB+ recommended
- **OS**: Debian 12 (installed by container script)

### Software Dependencies

- **Python**: 3.11+
- **Node.js**: 20.x
- **npm**: Latest version
- **Redis**: Latest version
- **Nginx**: Latest version
- **UFW**: Firewall management

## Support

For issues and questions, please refer to:
- [SearXNG Documentation](https://docs.searxng.org/)
- [MCP SearXNG GitHub](https://github.com/mcp-searxng/mcp-searxng)
- [Node.js Documentation](https://nodejs.org/en/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Nginx Documentation](https://nginx.org/en/docs/)

## License

This script is part of the script repository and is licensed under the GPL-3.0 license.

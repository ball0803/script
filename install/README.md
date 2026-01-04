# Scaffold Installation Script

## Overview

This script installs and configures Scaffold from source within a Proxmox VE LXC container. It handles all dependencies, service configuration, and system setup required for a complete Scaffold deployment.

## Features

- **Automated Dependency Installation**: Installs all required system packages
- **Docker Configuration**: Sets up Docker and Docker Compose
- **Poetry Installation**: Python dependency manager for Scaffold
- **Source Installation**: Clones and builds Scaffold from GitHub
- **Service Management**: Creates systemd service for easy management
- **Reverse Proxy**: Configures Nginx as reverse proxy
- **Environment Configuration**: Sets up .env file with proper settings

## Usage

This script is designed to run **inside the LXC container** after it has been created. It should be executed as root.

### Running the Script

```bash
# Execute the installation script
bash /install/scaffold-install.sh
```

### Using with Cloud-Init

For automated container provisioning, include this script in your cloud-init configuration:

```yaml
#cloud-config
write_files:
  - path: /root/install-scaffold.sh
    content: |
      #!/bin/bash
      source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
      color
      verb_ip6
      catch_errors
      setting_up_container
      network_check
      update_os
      
      # Rest of installation script...
      
      motd_ssh
      customize
      cleanup_lxc
    permissions: '0755'

runcmd:
  - [bash, /root/install-scaffold.sh]
```

## Installation Process

The script performs the following steps:

1. **System Update**: Updates all packages to latest versions
2. **Dependency Installation**: Installs Python, Docker, Nginx, and build tools
3. **Docker Configuration**: Enables and starts Docker service
4. **Poetry Installation**: Installs Python dependency manager
5. **Scaffold Setup**: Clones repository and configures .env file
6. **Service Build**: Builds Docker images from source
7. **Service Start**: Starts all Scaffold services
8. **Nginx Configuration**: Sets up reverse proxy
9. **Systemd Service**: Creates management service
10. **Cleanup**: Removes temporary files and customizes container

## Configuration

### Environment Variables

The script automatically configures the following environment variables in `/opt/scaffold/.env`:

```ini
# Scaffold Configuration
PROJECT_PATH=/opt/scaffold/codebase

# ChromaDB Settings
CHROMA_SERVER_HOST=localhost
CHROMA_SERVER_PORT=8000

# Neo4j Settings
NEO4J_URI=bolt://localhost:7687
```

### Nginx Configuration

Nginx is configured to proxy requests to:
- `/` → Scaffold API (port 8000)
- `/neo4j` → Neo4j UI (port 7474)

The configuration file is located at `/etc/nginx/conf.d/scaffold.conf`.

### Systemd Service

A systemd service is created at `/etc/systemd/system/scaffold.service` that manages all Docker containers.

## Services

After installation, the following services will be running:

| Service | Port | Description |
|---------|------|-------------|
| Scaffold API | 8000 | Main Scaffold service (MCP interface) |
| Neo4j | 7474, 7687 | Graph database for code relationships |
| ChromaDB | 8000 | Vector database for semantic search |
| Nginx | 80 | Reverse proxy for all services |

## Management

### Starting/Stopping Services

```bash
# Start all services
systemctl start scaffold

# Stop all services
systemctl stop scaffold

# Restart services
systemctl restart scaffold

# Check status
systemctl status scaffold

# View logs
journalctl -u scaffold -f
```

### Docker Management

```bash
# View running containers
docker ps

# View all containers
docker ps -a

# Check specific service logs
docker logs scaffold-mcp
docker logs scaffold-neo4j
docker logs scaffold-chromadb

# Restart a service
docker restart scaffold-mcp
```

## Codebase Setup

After installation, add your codebase to `/opt/scaffold/codebase`:

### Method 1: Direct Copy

```bash
# Copy your code to the codebase directory
cp -r /path/to/your/codebase /opt/scaffold/codebase
```

### Method 2: Mount External Storage

```bash
# On Proxmox host
mkdir -p /mnt/scaffold-codebase
cp -r /path/to/your/codebase/* /mnt/scaffold-codebase/

# Mount to container
pct set <CTID> -mp0 /mnt/scaffold-codebase,mp=/opt/scaffold/codebase
pct restart <CTID>
```

## Requirements

### System Requirements

- **CPU**: 2+ cores (4+ recommended)
- **RAM**: 4GB+ (8GB+ recommended)
- **Disk**: 10GB+ (SSD recommended)
- **Network**: Internet access for initial setup

### Software Dependencies

- Python 3.10+
- Git
- Docker & Docker Compose
- Nginx
- Build tools (gcc, python3-dev, etc.)

## Troubleshooting

### Common Issues

#### 1. Docker Permission Errors

**Symptoms**: "Permission denied" when running Docker commands

**Solution**:
```bash
usermod -aG docker root
systemctl restart docker
```

#### 2. Port Conflicts

**Symptoms**: Services fail to start, port already in use

**Solution**:
```bash
# Check which process is using the port
netstat -tulnp | grep <PORT>

# Stop conflicting services
systemctl stop <conflicting-service>
```

#### 3. Dependency Installation Failures

**Symptoms**: Package installation errors

**Solution**:
```bash
# Check internet connectivity
ping archive.ubuntu.com

# Retry with verbose mode
VAR_VERBOSE=yes bash /install/scaffold-install.sh
```

#### 4. Docker Build Failures

**Symptoms**: Scaffold build fails during docker compose build

**Solution**:
```bash
# Check available disk space
df -h

# Clean Docker system
docker system prune -a

# Retry the build
cd /opt/scaffold
docker compose build
```

### Debugging

```bash
# Enable verbose logging
export VAR_VERBOSE=yes

# Check system logs
journalctl -xe

# Check Docker logs
docker logs -f scaffold-mcp

# Test network connectivity
ping localhost
curl -v http://localhost:8000
```

## Security

### Changing Default Passwords

```bash
# Change Neo4j password
pct enter <CTID>
docker exec -it scaffold-neo4j bash
# Inside Neo4j container:
cypher-shell -u neo4j -p password ALTER USER neo4j SET PASSWORD 'newpassword'
```

### Securing the API

Add authentication to Nginx:

```bash
# Create password file
htpasswd -c /etc/nginx/.htpasswd username

# Edit Nginx configuration
cat > /etc/nginx/conf.d/scaffold.conf << 'EOF'
server {
    listen 80;
    server_name <CONTAINER_IP>;
    
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

# Reload Nginx
systemctl reload nginx
```

## See Also

- [Scaffold Container Creation README](../ct/README.md)
- [Scaffold Documentation](https://github.com/Beer-Bears/scaffold)
- [Neo4j Documentation](https://neo4j.com/docs/)
- [ChromaDB Documentation](https://docs.trychroma.com/)

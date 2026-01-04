# AGENTS.md - Scaffold Build Process Documentation

## Overview
This document serves as a comprehensive guide for building and maintaining the Scaffold installation scripts for Proxmox VE. It includes all the necessary information for automated build processes, testing, and deployment.

## Build Process

### 1. Initial Setup

```bash
# Clone the community-scripts repository for reference
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/community-scripts/ProxmoxVE.git

# Create a new directory for scaffold scripts
mkdir -p ~/scaffold-scripts/ct
mkdir -p ~/scaffold-scripts/install
mkdir -p ~/scaffold-scripts/ct/headers
```

### 2. Script Creation

#### scaffold.sh

```bash
cat > ~/scaffold-scripts/ct/scaffold.sh << 'EOF'
#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

APP="Scaffold"
var_tags="${var_tags:-rag;ai;code-analysis;python}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d "/opt/scaffold" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating Scaffold"
  pct exec "$CTID" -- bash -c "cd /opt/scaffold && git pull origin main"
  pct exec "$CTID" -- bash -c "cd /opt/scaffold && docker compose pull"
  pct exec "$CTID" -- bash -c "cd /opt/scaffold && docker compose up -d --build"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URLs:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL} (Scaffold API)"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7474${CL} (Neo4j UI - user: neo4j, pass: password)"
EOF

chmod +x ~/scaffold-scripts/ct/scaffold.sh
```

#### scaffold-install.sh

```bash
cat > ~/scaffold-scripts/install/scaffold-install.sh << 'EOF'
#!/usr/bin/env bash

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y git curl python3 python3-pip python3-venv \
  docker.io docker-compose-plugin nginx build-essential libssl-dev \
  zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget \
  llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev

msg_info "Configuring Docker"
$STD systemctl enable --now docker
$STD usermod -aG docker root

msg_info "Installing Poetry"
$STD curl -sSL https://install.python-poetry.org | python3 -

msg_info "Setting up Scaffold"
import_local_ip

# Clone scaffold repository
$STD git clone https://github.com/Beer-Bears/scaffold.git /opt/scaffold
cd /opt/scaffold

# Create .env from example
$STD cp .env.example .env

# Configure .env file
sed -i -e "s|^PROJECT_PATH=.*|PROJECT_PATH=/opt/scaffold/codebase|" \
  -e "s|^CHROMA_SERVER_HOST=.*|CHROMA_SERVER_HOST=localhost|" \
  -e "s|^CHROMA_SERVER_PORT=.*|CHROMA_SERVER_PORT=8000|" \
  -e "s|^NEO4J_URI=.*|NEO4J_URI=bolt://localhost:7687|" \
  .env

# Create codebase directory
mkdir -p /opt/scaffold/codebase

msg_info "Building Scaffold from source"
$STD docker compose build

msg_info "Starting Scaffold services"
$STD docker compose up -d

msg_info "Configuring Nginx"
cat <<EOF2 >/etc/nginx/conf.d/scaffold.conf
server {
    listen 80;
    server_name $LOCAL_IP;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /neo4j {
        proxy_pass http://localhost:7474;
        proxy_set_header Host \$host;
    }
}
EOF2
systemctl reload nginx

msg_info "Creating systemd service for Scaffold"
cat <<EOF2 >/etc/systemd/system/scaffold.service
[Unit]
Description=Scaffold RAG System
After=network.target docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker compose -f /opt/scaffold/docker-compose.yaml up -d
ExecStop=/usr/bin/docker compose -f /opt/scaffold/docker-compose.yaml down
WorkingDirectory=/opt/scaffold

[Install]
WantedBy=multi-user.target
EOF2

$STD systemctl daemon-reload
$STD systemctl enable scaffold

motd_ssh
customize
cleanup_lxc
EOF

chmod +x ~/scaffold-scripts/install/scaffold-install.sh
```

#### Header File

```bash
cat > ~/scaffold-scripts/ct/headers/scaffold << 'EOF'
    ___   _________         __  __
   |__ \ / ____/   | __  __/ /_/ /_ 
   __/ // /_  / /| |/ / / / __/ __ \
  / __// __/ / ___ / /_/ / /_/ / / /
 /____/_/   /_/  |_\__,_/\__/_/ /_/
EOF
```

### 3. Testing the Build

```bash
# Test the container creation script
cd ~/scaffold-scripts
bash ct/scaffold.sh

# Test with different configurations
VAR_CPU=4 VAR_RAM=8192 VAR_DISK=20 bash ct/scaffold.sh
```

### 4. Validation Checks

```bash
# Verify script permissions
ls -la ct/ install/

# Check for syntax errors
bash -n ct/scaffold.sh
bash -n install/scaffold-install.sh

# Verify dependencies
grep -E "(apt install|pip install|docker|git)" install/scaffold-install.sh
```

## Automated Build Process

### CI/CD Pipeline

```yaml
# Example GitHub Actions workflow
name: Build Scaffold Scripts

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up environment
        run: |
          sudo apt update
          sudo apt install -y bash curl git
      
      - name: Create script directories
        run: |
          mkdir -p ct/headers
          mkdir -p install
      
      - name: Create scaffold.sh
        run: |
          cat > ct/scaffold.sh << 'SCRIPT'
          #!/usr/bin/env bash
          source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
          
          APP="Scaffold"
          var_tags="${var_tags:-rag;ai;code-analysis;python}"
          var_cpu="${var_cpu:-2}"
          var_ram="${var_ram:-4096}"
          var_disk="${var_disk:-10}"
          var_os="${var_os:-debian}"
          var_version="${var_version:-12}"
          var_unprivileged="${var_unprivileged:-0}"
          
          header_info "$APP"
          variables
          color
          catch_errors
          
          function update_script() {
            header_info
            check_container_storage
            check_container_resources
            
            if [[ ! -d "/opt/scaffold" ]]; then
              msg_error "No ${APP} Installation Found!"
              exit
            fi
            
            msg_info "Updating Scaffold"
            pct exec "$CTID" -- bash -c "cd /opt/scaffold && git pull origin main"
            pct exec "$CTID" -- bash -c "cd /opt/scaffold && docker compose pull"
            pct exec "$CTID" -- bash -c "cd /opt/scaffold && docker compose up -d --build"
            msg_ok "Updated successfully!"
            exit
          }
          
          start
          build_container
          description
          
          msg_ok "Completed Successfully!\n"
          echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
          echo -e "${INFO}${YW} Access it using the following URLs:${CL}"
          echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL} (Scaffold API)"
          echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7474${CL} (Neo4j UI - user: neo4j, pass: password)"
          SCRIPT
          chmod +x ct/scaffold.sh
      
      - name: Create scaffold-install.sh
        run: |
          cat > install/scaffold-install.sh << 'SCRIPT'
          #!/usr/bin/env bash
          
          source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
          color
          verb_ip6
          catch_errors
          setting_up_container
          network_check
          update_os
          
          msg_info "Installing Dependencies"
          $STD apt install -y git curl python3 python3-pip python3-venv \
            docker.io docker-compose-plugin nginx build-essential libssl-dev \
            zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget \
            llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev
          
          msg_info "Configuring Docker"
          $STD systemctl enable --now docker
          $STD usermod -aG docker root
          
          msg_info "Installing Poetry"
          $STD curl -sSL https://install.python-poetry.org | python3 -
          
          msg_info "Setting up Scaffold"
          import_local_ip
          
          # Clone scaffold repository
          $STD git clone https://github.com/Beer-Bears/scaffold.git /opt/scaffold
          cd /opt/scaffold
          
          # Create .env from example
          $STD cp .env.example .env
          
          # Configure .env file
          sed -i -e "s|^PROJECT_PATH=.*|PROJECT_PATH=/opt/scaffold/codebase|" \
            -e "s|^CHROMA_SERVER_HOST=.*|CHROMA_SERVER_HOST=localhost|" \
            -e "s|^CHROMA_SERVER_PORT=.*|CHROMA_SERVER_PORT=8000|" \
            -e "s|^NEO4J_URI=.*|NEO4J_URI=bolt://localhost:7687|" \
            .env
          
          # Create codebase directory
          mkdir -p /opt/scaffold/codebase
          
          msg_info "Building Scaffold from source"
          $STD docker compose build
          
          msg_info "Starting Scaffold services"
          $STD docker compose up -d
          
          msg_info "Configuring Nginx"
          cat <<EOF2 >/etc/nginx/conf.d/scaffold.conf
          server {
              listen 80;
              server_name $LOCAL_IP;
              
              location / {
                  proxy_pass http://localhost:8000;
                  proxy_set_header Host \$host;
                  proxy_set_header X-Real-IP \$remote_addr;
                  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
              }
              
              location /neo4j {
                  proxy_pass http://localhost:7474;
                  proxy_set_header Host \$host;
              }
          }
          EOF2
          systemctl reload nginx
          
          msg_info "Creating systemd service for Scaffold"
          cat <<EOF2 >/etc/systemd/system/scaffold.service
          [Unit]
          Description=Scaffold RAG System
          After=network.target docker.service
          
          [Service]
          Type=oneshot
          RemainAfterExit=yes
          ExecStart=/usr/bin/docker compose -f /opt/scaffold/docker-compose.yaml up -d
          ExecStop=/usr/bin/docker compose -f /opt/scaffold/docker-compose.yaml down
          WorkingDirectory=/opt/scaffold
          
          [Install]
          WantedBy=multi-user.target
          EOF2
          
          $STD systemctl daemon-reload
          $STD systemctl enable scaffold
          
          motd_ssh
          customize
          cleanup_lxc
          SCRIPT
          chmod +x install/scaffold-install.sh
      
      - name: Create header
        run: |
          cat > ct/headers/scaffold << 'HEADER'
          ___   _________         __  __
         |__ \ / ____/   | __  __/ /_/ /_ 
         __/ // /_  / /| |/ / / / __/ __ \
        / __// __/ / ___ / /_/ / /_/ / / /
       /____/_/   /_/  |_\__,_/\__/_/ /_/
          HEADER
      
      - name: Verify scripts
        run: |
          bash -n ct/scaffold.sh
          bash -n install/scaffold-install.sh
          ls -la ct/ install/
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: scaffold-scripts
          path: |
            ct/
            install/
```

## Testing Strategy

### Unit Tests

```bash
# Test script syntax
bash -n ct/scaffold.sh
bash -n install/scaffold-install.sh

# Test variable substitution
VAR_CPU=4 bash -c 'source ct/scaffold.sh && echo "CPU: $var_cpu"'
```

### Integration Tests

```bash
# Create a test container
bash ct/scaffold.sh

# Verify container creation
pct list | grep scaffold

# Check if services are running
pct exec <CTID> docker ps

# Test API endpoint
curl -v http://<CONTAINER_IP>:8000
```

### Regression Tests

```bash
# Test update functionality
bash ct/scaffold.sh --update

# Test resource scaling
VAR_CPU=2 VAR_RAM=4096 bash ct/scaffold.sh
VAR_CPU=4 VAR_RAM=8192 bash ct/scaffold.sh
```

## Deployment Process

### Manual Deployment

```bash
# Copy scripts to target location
cp -r ~/scaffold-scripts/* /path/to/proxmox-scripts/

# Make scripts executable
chmod +x /path/to/proxmox-scripts/ct/scaffold.sh
chmod +x /path/to/proxmox-scripts/install/scaffold-install.sh

# Run the installation
cd /path/to/proxmox-scripts
bash ct/scaffold.sh
```

### Automated Deployment

```bash
# Using Ansible
cat > deploy.yml << 'EOF'
---
- hosts: proxmox
  become: yes
  tasks:
    - name: Create scaffold script directories
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      loop:
        - /opt/proxmox-scripts/ct
        - /opt/proxmox-scripts/install
        - /opt/proxmox-scripts/ct/headers

    - name: Deploy scaffold.sh
      copy:
        src: ~/scaffold-scripts/ct/scaffold.sh
        dest: /opt/proxmox-scripts/ct/scaffold.sh
        mode: '0755'

    - name: Deploy scaffold-install.sh
      copy:
        src: ~/scaffold-scripts/install/scaffold-install.sh
        dest: /opt/proxmox-scripts/install/scaffold-install.sh
        mode: '0755'

    - name: Deploy header
      copy:
        src: ~/scaffold-scripts/ct/headers/scaffold
        dest: /opt/proxmox-scripts/ct/headers/scaffold
        mode: '0644'

    - name: Run scaffold installation
      command: bash /opt/proxmox-scripts/ct/scaffold.sh
      args:
        chdir: /opt/proxmox-scripts
EOF

ansible-playbook -i inventory deploy.yml
```

## Maintenance

### Version Updates

```bash
# Update to latest community-scripts patterns
cd ~/scaffold-scripts
git clone https://github.com/community-scripts/ProxmoxVE.git temp-reference

# Compare and update scripts
# Manual review recommended
```

### Dependency Updates

```bash
# Update Python dependencies
pct exec <CTID> docker exec scaffold-mcp poetry update

# Update Docker images
pct exec <CTID> docker compose pull
pct exec <CTID> docker compose up -d
```

### Security Updates

```bash
# Update system packages
pct exec <CTID> apt update && apt upgrade -y

# Update Docker
pct exec <CTID> apt install -y docker.io docker-compose-plugin

# Restart services
pct exec <CTID> systemctl restart scaffold
```

## Documentation Generation

### Script Documentation

```bash
# Generate documentation for scaffold.sh
cat > DOCUMENTATION.md << 'EOF'
# Scaffold Installation Scripts

## Files

### ct/scaffold.sh

**Purpose**: Create a Proxmox VE LXC container for Scaffold

**Variables**:
- `APP`: Application name (default: "Scaffold")
- `var_tags`: Container tags (default: "rag;ai;code-analysis;python")
- `var_cpu`: CPU cores (default: 2)
- `var_ram`: RAM in MB (default: 4096)
- `var_disk`: Disk size in GB (default: 10)
- `var_os`: Operating system (default: debian)
- `var_version`: OS version (default: 12)
- `var_unprivileged`: Privileged mode (default: 0 - privileged)

**Functions**:
- `update_script()`: Update existing installation

**Usage**:
```bash
# Basic installation
bash ct/scaffold.sh

# Custom resources
VAR_CPU=4 VAR_RAM=8192 VAR_DISK=20 bash ct/scaffold.sh

# Update existing installation
bash ct/scaffold.sh --update
```

### install/scaffold-install.sh

**Purpose**: Install and configure Scaffold within the LXC container

**Installation Steps**:
1. Install system dependencies
2. Configure Docker
3. Install Poetry
4. Clone Scaffold repository
5. Configure environment
6. Build Docker images
7. Start services
8. Configure Nginx
9. Create systemd service

**Configuration**:
- Scaffold API: http://<IP>:8000
- Neo4j UI: http://<IP>:7474
- Codebase: /opt/scaffold/codebase

**Usage**:
```bash
# Run inside container
bash /install/scaffold-install.sh
```

### ct/headers/scaffold

**Purpose**: ASCII art header for Scaffold

**Content**:
```
    ___   _________         __  __
   |__ \ / ____/   | __  __/ /_/ /_ 
   __/ // /_  / /| |/ / / / __/ __ \
  / __// __/ / ___ / /_/ / /_/ / / /
 /____/_/   /_/  |_\__,_/\__/_/ /_/
```
EOF
```

### Usage Examples

```bash
# Generate usage examples
cat > USAGE_EXAMPLES.md << 'EOF'
# Scaffold Usage Examples

## Basic Installation

```bash
# Clone this repository
git clone https://github.com/yourusername/scaffold-proxmox.git
cd scaffold-proxmox

# Create container with default settings
bash ct/scaffold.sh
```

## Custom Resource Allocation

```bash
# High-performance configuration
VAR_CPU=4 VAR_RAM=8192 VAR_DISK=20 bash ct/scaffold.sh

# Minimum configuration (for testing)
VAR_CPU=2 VAR_RAM=4096 VAR_DISK=10 bash ct/scaffold.sh
```

## Adding Codebase

```bash
# Method 1: Direct copy
pct enter <CTID>
cp -r /path/to/your/codebase /opt/scaffold/codebase

# Method 2: Mount external storage
# On Proxmox host
mkdir -p /mnt/scaffold-codebase
cp -r /path/to/your/codebase/* /mnt/scaffold-codebase/

# Mount to container
pct set <CTID> -mp0 /mnt/scaffold-codebase,mp=/opt/scaffold/codebase
pct restart <CTID>
```

## Managing Services

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

## Updating Scaffold

```bash
# Update to latest version
bash ct/scaffold.sh --update

# Manual update
pct enter <CTID>
cd /opt/scaffold
git pull origin main
docker compose pull
docker compose up -d --build
```

## Troubleshooting

```bash
# Check Docker status
docker ps -a

# View container logs
docker logs scaffold-mcp

# Check Neo4j status
docker logs scaffold-neo4j

# Check ChromaDB status
docker logs scaffold-chromadb

# Test API connectivity
curl -v http://localhost:8000
```
EOF
```

## Release Process

### Versioning

```bash
# Follow semantic versioning
# MAJOR.MINOR.PATCH

# Example version scheme
# 1.0.0 - Initial release
# 1.1.0 - New features
# 1.1.1 - Bug fixes
# 2.0.0 - Breaking changes
```

### Release Checklist

```bash
# Before release
1. Update version numbers in scripts
2. Test all functionality
3. Update documentation
4. Create release notes
5. Tag the release

# Example release process
cat > release.sh << 'EOF'
#!/bin/bash

VERSION="1.0.0"

# Update version in scripts
sed -i "s/version=.*/version=$VERSION/" ct/scaffold.sh

# Create release notes
cat > RELEASE_NOTES.md << 'NOTES'
# Scaffold Proxmox VE - Release $VERSION

## Changes
- Initial release
- Support for Scaffold v0.1.2
- Complete installation and configuration

## Features
- Automatic container creation
- Full Scaffold installation from source
- Nginx reverse proxy configuration
- Systemd service management
- Update functionality

## Requirements
- Proxmox VE 7.x or 8.x
- 2+ CPU cores
- 4GB+ RAM
- 10GB+ disk space

## Usage
```bash
bash ct/scaffold.sh
```

## Known Issues
- None

## Future Enhancements
- Backup/restore functionality
- Health checks
- Monitoring integration
NOTES

# Tag the release
git tag -a v$VERSION -m "Release $VERSION"
git push origin v$VERSION

# Create GitHub release
gh release create v$VERSION \
  --title "Release $VERSION" \
  --notes-file RELEASE_NOTES.md \
  --draft
EOF

chmod +x release.sh
./release.sh
```

## Monitoring and Analytics

### Health Checks

```bash
# Create health check script
cat > healthcheck.sh << 'EOF'
#!/bin/bash

CTID=$(pct list | grep scaffold | awk '{print $1}')

if [ -z "$CTID" ]; then
  echo "ERROR: Scaffold container not found"
  exit 1
fi

# Check if container is running
if ! pct status $CTID | grep -q "status: running"; then
  echo "ERROR: Container $CTID is not running"
  exit 1
fi

# Check if Docker is running
if ! pct exec $CTID docker info >/dev/null 2>&1; then
  echo "ERROR: Docker is not running in container"
  exit 1
fi

# Check if services are running
SERVICES=("scaffold-mcp" "scaffold-neo4j" "scaffold-chromadb")
for service in "${SERVICES[@]}"; do
  if ! pct exec $CTID docker ps | grep -q "$service"; then
    echo "ERROR: Service $service is not running"
    exit 1
  fi
done

# Check API endpoint
if ! pct exec $CTID curl -s http://localhost:8000 >/dev/null; then
  echo "ERROR: Scaffold API is not responding"
  exit 1
fi

echo "All checks passed!"
exit 0
EOF

chmod +x healthcheck.sh
```

### Performance Monitoring

```bash
# Monitor resource usage
cat > monitor.sh << 'EOF'
#!/bin/bash

CTID=$(pct list | grep scaffold | awk '{print $1}')

if [ -z "$CTID" ]; then
  echo "ERROR: Scaffold container not found"
  exit 1
fi

echo "=== Scaffold Container Resources ==="
echo ""

# CPU usage
CPU_USAGE=$(pct status $CTID | grep cpu | awk '{print $2}')
echo "CPU Usage: $CPU_USAGE"

# Memory usage
MEM_USAGE=$(pct status $CTID | grep mem | awk '{print $2}')
echo "Memory Usage: $MEM_USAGE"

# Disk usage
DISK_USAGE=$(pct exec $CTID df -h /opt/scaffold | awk 'NR==2 {print $5}')
echo "Disk Usage: $DISK_USAGE"

echo ""
echo "=== Docker Container Status ==="
echo ""

# Docker resource usage
pct exec $CTID docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo ""
echo "=== Service Health ==="
echo ""

# Check service health
SERVICES=("scaffold-mcp" "scaffold-neo4j" "scaffold-chromadb")
for service in "${SERVICES[@]}"; do
  STATUS=$(pct exec $CTID docker inspect -f '{{.State.Health.Status}}' $service 2>/dev/null || echo "unknown")
  echo "$service: $STATUS"
done
EOF

chmod +x monitor.sh
```

## Support and Troubleshooting

### Common Issues

```bash
# Docker permission errors
pct exec <CTID> usermod -aG docker root
pct exec <CTID> systemctl restart docker

# Port conflicts
pct exec <CTID> netstat -tulnp | grep <PORT>

# Insufficient resources
pct set <CTID> -cores 4 -memory 8192
pct restart <CTID>

# Database connection issues
pct exec <CTID> docker restart scaffold-neo4j scaffold-chromadb
```

### Debugging

```bash
# Enable verbose logging
export VAR_VERBOSE=yes

# Check system logs
journalctl -xe

# Check Docker logs
pct exec <CTID> docker logs -f scaffold-mcp

# Test network connectivity
pct exec <CTID> ping localhost
pct exec <CTID> curl -v http://localhost:8000
```

## Contributing Guidelines

### Code Standards

```bash
# Follow these standards for contributions

1. Use consistent indentation (2 spaces)
2. Add comments for complex logic
3. Follow community-scripts patterns
4. Test all changes
5. Update documentation

# Example contribution workflow
cat > CONTRIBUTING.md << 'EOF'
# Contributing to Scaffold Proxmox VE

## How to Contribute

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Code Standards

- Use bash for all scripts
- Follow POSIX compliance
- Use community-scripts helper functions
- Add error handling
- Include usage examples

## Testing Requirements

- Test on Proxmox VE 7.x and 8.x
- Test with different resource configurations
- Test update functionality
- Test error handling

## Documentation

- Update README.md
- Add usage examples
- Document new features
- Update troubleshooting section

## Review Process

All contributions will be reviewed for:
- Code quality
- Documentation
- Testing
- Compatibility
- Security
EOF
```

## References

### External Resources

- [Community Scripts Repository](https://github.com/community-scripts/ProxmoxVE)
- [Scaffold Documentation](https://github.com/Beer-Bears/scaffold)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs)
- [Docker Documentation](https://docs.docker.com)
- [Neo4j Documentation](https://neo4j.com/docs/)
- [ChromaDB Documentation](https://docs.trychroma.com/)

### Internal References

- [build.func](https://github.com/community-scripts/ProxmoxVE/blob/main/misc/build.func)
- [core.func](https://github.com/community-scripts/ProxmoxVE/blob/main/misc/core.func)
- [install.func](https://github.com/community-scripts/ProxmoxVE/blob/main/misc/install.func)
- [error_handler.func](https://github.com/community-scripts/ProxmoxVE/blob/main/misc/error_handler.func)

## Appendix

### Useful Commands

```bash
# Container management
pct list
pct create
pct start
pct stop
pct enter
pct destroy

# Docker management
docker ps
docker ps -a
docker logs
docker exec
docker compose up
docker compose down

# System management
systemctl start
systemctl stop
systemctl restart
systemctl status
journalctl -u

# Network tools
curl
netstat
ping
ss
```

### Configuration Examples

```bash
# Different resource configurations

# Small (Testing)
VAR_CPU=2 VAR_RAM=4096 VAR_DISK=10

# Medium (Production)
VAR_CPU=4 VAR_RAM=8192 VAR_DISK=20

# Large (Enterprise)
VAR_CPU=8 VAR_RAM=16384 VAR_DISK=50

# Custom network configuration
VAR_NET=192.168.1.100/24 VAR_GATEWAY=192.168.1.1

# SSH access
VAR_SSH=yes
```

### Error Codes

```bash
# Common error codes and their meanings

0 - Success
1 - General error
2 - Container creation failed
3 - Installation failed
4 - Update failed
5 - Resource allocation failed
6 - Network configuration failed
7 - Dependency installation failed
8 - Docker configuration failed
9 - Service startup failed
```

---

**Note**: This AGENTS.md file serves as a comprehensive guide for building, testing, and maintaining the Scaffold installation scripts for Proxmox VE. It includes all necessary information for automated processes and manual operations.

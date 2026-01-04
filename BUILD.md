# Scaffold Installation Plan

## Overview
This document outlines the plan to create a Proxmox VE helper script for installing Scaffold, a Structural RAG (Retrieval-Augmented Generation) system for large codebases.

## Repository Structure

### Files to Create

1. **ct/scaffold.sh** - Container creation script
2. **install/scaffold-install.sh** - Container installation script  
3. **ct/headers/scaffold** - ASCII art header

## Technical Requirements

### System Requirements
- **Proxmox VE** 7.x or 8.x
- **LXC Container** with privileged mode
- **Resources**:
  - CPU: 2+ cores (Neo4j is resource-intensive)
  - RAM: 4GB+ (Neo4j and ChromaDB need memory)
  - Disk: 10GB+ (for databases and codebase)
  - Ports: 8000 (API), 7474 (Neo4j UI), 7687 (Neo4j Bolt)

### Software Dependencies
- Python 3.10+
- Git
- Docker & Docker Compose
- Build tools (gcc, python3-dev, etc.)
- Neo4j (graph database)
- ChromaDB (vector database)
- Nginx (reverse proxy)
- Node.js (for some dependencies)

## Implementation Details

### 1. Container Creation Script (ct/scaffold.sh)

**Purpose**: Create a privileged LXC container with appropriate resources for Scaffold.

**Key Features**:
- Uses community-scripts build.func framework
- Sets default resources (2 CPU, 4GB RAM, 10GB disk)
- Enables privileged mode for Docker support
- Provides update functionality
- Displays access URLs after installation

**Variables**:
```bash
APP="Scaffold"
var_tags="rag;ai;code-analysis;python"
var_cpu="2"
var_ram="4096"
var_disk="10"
var_os="debian"
var_version="12"
var_unprivileged="0"  # Privileged mode required
```

### 2. Installation Script (install/scaffold-install.sh)

**Purpose**: Install and configure Scaffold from source within the LXC container.

**Installation Steps**:
1. Install system dependencies (Python, Docker, build tools)
2. Configure Docker and add user to docker group
3. Install Poetry (Python dependency manager)
4. Clone Scaffold repository from GitHub
5. Create and configure .env file
6. Build Docker images from source
7. Start all services (Scaffold, Neo4j, ChromaDB)
8. Configure Nginx as reverse proxy
9. Create systemd service for management
10. Clean up and customize container

**Configuration**:
- Scaffold API: http://<IP>:8000
- Neo4j UI: http://<IP>:7474 (user: neo4j, pass: password)
- Codebase directory: /opt/scaffold/codebase

### 3. ASCII Art Header (ct/headers/scaffold)

```bash
    ___   _________         __  __
   |__ \ / ____/   | __  __/ /_/ /_ 
   __/ // /_  / /| |/ / / / __/ __ \
  / __// __/ / ___ / /_/ / /_/ / / /
 /____/_/   /_/  |_\__,_/\__/_/ /_/
```

## Usage Instructions

### For End Users

1. **Create Container**:
   ```bash
   bash scaffold.sh
   ```

2. **Access Container**:
   ```bash
   pct enter <CTID>
   ```

3. **Add Codebase**:
   - Copy files to `/opt/scaffold/codebase`
   - Or mount external storage to `/opt/scaffold/codebase`

4. **Manage Services**:
   ```bash
   systemctl start/stop/restart scaffold
   ```

### For Developers

1. **Clone Repository**:
   ```bash
   git clone https://github.com/Beer-Bears/scaffold.git
   cd scaffold
   ```

2. **Create Environment**:
   ```bash
   cp .env.example .env
   ```

3. **Add Codebase**:
   ```bash
   mkdir -p codebase
   cp -r /path/to/your/project/* ./codebase/
   ```

4. **Build and Run**:
   ```bash
   docker compose build
   docker compose up -d
   ```

## Customization Options

The script supports all standard community-scripts variables:
- `var_cpu`, `var_ram`, `var_disk` - Resource allocation
- `var_ctid`, `var_hostname` - Container identification
- `var_net`, `var_gateway` - Network configuration
- `var_ssh` - SSH access
- `var_tags` - Container tags

## Update Mechanism

The update function will:
1. Pull latest code from GitHub
2. Rebuild Docker images
3. Restart services with new code

## Troubleshooting

### Common Issues

1. **Docker Permission Errors**:
   - Ensure user is in docker group
   - Check Docker service is running

2. **Port Conflicts**:
   - Verify ports 8000, 7474, 7687 are available
   - Check for conflicting services

3. **Resource Constraints**:
   - Increase CPU/RAM allocation if Neo4j is slow
   - Monitor disk space for database growth

4. **Python Dependencies**:
   - Use Poetry to resolve dependency issues
   - Check Python version compatibility

## References

- [Scaffold GitHub Repository](https://github.com/Beer-Bears/scaffold)
- [Community Scripts Documentation](https://github.com/community-scripts/ProxmoxVE)
- [Neo4j Documentation](https://neo4j.com/docs/)
- [ChromaDB Documentation](https://docs.trychroma.com/)

## Future Enhancements

1. Add backup/restore functionality
2. Implement health checks
3. Add monitoring and logging
4. Support for multiple codebases
5. Auto-scaling for resource-intensive workloads

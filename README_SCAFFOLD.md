# Scaffold Installation for Proxmox VE

## Overview

This repository contains scripts to install **Scaffold**, a Structural RAG (Retrieval-Augmented Generation) system for large codebases, in a Proxmox VE LXC container.

Scaffold transforms your source code into a living knowledge graph stored in a graph database, enabling precise context injection for LLMs and AI agents.

## Features

- **Structural RAG**: Captures structural relationships between code entities
- **Graph Database**: Neo4j for entity relationships
- **Vector Database**: ChromaDB for semantic search
- **MCP Interface**: Integration with AI agents and IDEs
- **Self-Hosted**: Full control over your code analysis

## Prerequisites

### Hardware Requirements
- **CPU**: 2+ cores (4+ recommended for large codebases)
- **RAM**: 4GB+ (8GB+ recommended for better performance)
- **Disk**: 10GB+ (SSD recommended for database performance)
- **Network**: Stable internet connection for initial setup

### Software Requirements
- Proxmox VE 7.x or 8.x
- LXC container support
- Internet access for package downloads

## Installation

### Quick Start

```bash
# Clone this repository
git clone https://github.com/yourusername/scaffold-proxmox.git
cd scaffold-proxmox

# Create the LXC container
bash ct/scaffold.sh
```

### Advanced Installation

For more control over the installation process:

```bash
# Set custom resources
VAR_CPU=4 VAR_RAM=8192 VAR_DISK=20 bash ct/scaffold.sh

# Or use interactive mode (no variables needed)
bash ct/scaffold.sh
```

## Post-Installation

### Access the Services

After installation completes, you can access:

- **Scaffold API**: `http://<CONTAINER_IP>:8000`
- **Neo4j UI**: `http://<CONTAINER_IP>:7474` (user: `neo4j`, password: `password`)
- **Container Shell**: `pct enter <CTID>`

### Add Your Codebase

There are two ways to add your codebase for analysis:

#### Method 1: Direct Copy (Recommended for small projects)

```bash
# Enter the container
pct enter <CTID>

# Copy your code to the codebase directory
cp -r /path/to/your/codebase /opt/scaffold/codebase
```

#### Method 2: Mount External Storage (Recommended for large projects)

```bash
# On the Proxmox host, create a directory
mkdir -p /mnt/scaffold-codebase

# Copy your code to this directory
cp -r /path/to/your/codebase/* /mnt/scaffold-codebase/

# Mount the directory to the container
pct set <CTID> -mp0 /mnt/scaffold-codebase,mp=/opt/scaffold/codebase

# Restart the container
pct restart <CTID>
```

### Configure MCP Client

To use Scaffold with an MCP-compatible client (like Cursor IDE):

```json
{
  "mcpServers": {
    "scaffold-mcp": {
      "url": "http://<CONTAINER_IP>:8000/mcp"
    }
  }
}
```

## Usage

### Basic Commands

```bash
# Start all services
systemctl start scaffold

# Stop all services
systemctl stop scaffold

# Restart services
systemctl restart scaffold

# Check service status
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

# Check container logs
docker logs scaffold-mcp

# Restart a specific service
docker restart scaffold-mcp
```

## Configuration

### Environment Variables

Edit `/opt/scaffold/.env` to customize the configuration:

```ini
# ChromaDB Settings
CHROMA_SERVER_HOST=chromadb
CHROMA_SERVER_PORT=8000
CHROMA_COLLECTION_NAME=scaffold_data

# Neo4j Credentials
NEO4J_USER=neo4j
NEO4J_PASSWORD=password
NEO4J_URI=bolt://neo4j:password@neo4j:7687

# Project Path
PROJECT_PATH=/opt/scaffold/codebase
```

### Nginx Configuration

The Nginx configuration is located at `/etc/nginx/conf.d/scaffold.conf`. You can customize:

- SSL/TLS settings
- Authentication requirements
- Rate limiting
- Additional proxy settings

## Updating

To update Scaffold to the latest version:

```bash
# Update the container
bash ct/scaffold.sh --update

# Or manually update
pct enter <CTID>
cd /opt/scaffold
git pull origin main
docker compose pull
docker compose up -d --build
```

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

#### 3. Insufficient Resources

**Symptoms**: Neo4j or ChromaDB crashes, slow performance

**Solution**:
```bash
# Increase container resources
pct set <CTID> -cores 4 -memory 8192
pct restart <CTID>
```

#### 4. Database Connection Issues

**Symptoms**: Scaffold fails to start, database connection errors

**Solution**:
```bash
# Check database containers
docker ps | grep -E "neo4j|chroma"

# Restart databases
docker restart scaffold-neo4j scaffold-chromadb

# Check logs
docker logs scaffold-neo4j
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

```bash
# Add authentication to Nginx
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

# Create password file
htpasswd -c /etc/nginx/.htpasswd username
systemctl reload nginx
```

### Firewall Configuration

```bash
# On Proxmox host, allow required ports
iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
iptables -A INPUT -p tcp --dport 7474 -j ACCEPT
iptables -A INPUT -p tcp --dport 7687 -j ACCEPT
```

## Performance Optimization

### Resource Tuning

```bash
# Adjust Docker resource limits
cat > /opt/scaffold/docker-compose.yaml << 'EOF'
services:
  scaffold-mcp:
    image: ghcr.io/beer-bears/scaffold:latest
    container_name: scaffold-mcp
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
    # ... rest of configuration
EOF
```

### Database Optimization

```bash
# Configure Neo4j memory settings
cat > /opt/scaffold/neo4j.conf << 'EOF'
dbms.memory.heap.initial_size=2g
dbms.memory.heap.max_size=4g
dbms.memory.pagecache.size=4g
EOF
```

### Storage Optimization

```bash
# Use tmpfs for temporary files (if you have enough RAM)
mount -t tmpfs -o size=2G tmpfs /opt/scaffold/tmp
```

## Backup and Restore

### Backup

```bash
# Backup the entire scaffold directory
pct exec <CTID> tar -czvf /backup/scaffold-$(date +%Y%m%d).tar.gz /opt/scaffold

# Backup databases separately
pct exec <CTID> docker exec scaffold-neo4j bash -c "neo4j-admin dump --database=neo4j --to=/backups/neo4j.dump"
pct exec <CTID> docker exec scaffold-chromadb bash -c "chroma backup /backups/chroma"
```

### Restore

```bash
# Stop services
pct exec <CTID> systemctl stop scaffold

# Restore from backup
pct exec <CTID> tar -xzvf /backup/scaffold-20240101.tar.gz -C /

# Start services
pct exec <CTID> systemctl start scaffold
```

## Contributing

If you'd like to contribute to this project:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:

- GitHub Issues: [https://github.com/yourusername/scaffold-proxmox/issues](https://github.com/yourusername/scaffold-proxmox/issues)
- Proxmox Forum: [https://forum.proxmox.com](https://forum.proxmox.com)
- Scaffold Discord: [https://discord.gg/scaffold](https://discord.gg/scaffold)

## Resources

- [Scaffold Documentation](https://github.com/Beer-Bears/scaffold)
- [Neo4j Documentation](https://neo4j.com/docs/)
- [ChromaDB Documentation](https://docs.trychroma.com/)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs)
- [Docker Documentation](https://docs.docker.com)

---

**Note**: This installation guide assumes you have basic familiarity with Proxmox VE, LXC containers, and command-line interfaces.

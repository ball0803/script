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
  nginx build-essential libssl-dev \
  zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget \
  libffi-dev

msg_info "Installing Docker"
$STD sh <(curl -fsSL https://get.docker.com)
$STD systemctl enable --now docker
$STD usermod -aG docker root

# Fix Docker permission issues
$STD chmod 666 /var/run/docker.sock
$STD systemctl restart docker

msg_info "Installing Docker Compose"
# Install Docker Compose using the official convenience script
$STD curl -fsSL https://get.docker.com -o get-docker.sh
$STD sh get-docker.sh --compose-plugin
rm -f get-docker.sh

msg_info "Installing Poetry"
$STD curl -sSL https://install.python-poetry.org | python3 -

msg_info "Setting up Scaffold"
import_local_ip

# Download scaffold configuration files
mkdir -p /opt/scaffold
cd /opt/scaffold

# Download docker-compose.yaml
$STD curl -fsSL https://raw.githubusercontent.com/Beer-Bears/scaffold/refs/heads/main/docker-compose.yaml -o docker-compose.yaml

# Download .env.example and create .env
$STD curl -fsSL https://raw.githubusercontent.com/Beer-Bears/scaffold/refs/heads/main/.env.example -o .env.example
$STD cp .env.example .env

# Configure .env file
sed -i -e "s|^PROJECT_PATH=.*|PROJECT_PATH=/opt/scaffold|" \
  -e "s|^CHROMA_SERVER_HOST=.*|CHROMA_SERVER_HOST=localhost|" \
  -e "s|^CHROMA_SERVER_PORT=.*|CHROMA_SERVER_PORT=8000|" \
  -e "s|^NEO4J_URI=.*|NEO4J_URI=bolt://localhost:7687|" \
  .env

# Create codebase directory
mkdir -p /opt/scaffold/codebase

msg_info "Using pre-built Scaffold Docker image"
# Use pre-built image instead of building from source
$STD docker pull ghcr.io/beer-bears/scaffold:latest || \
  $STD docker pull beerbears/scaffold:latest

msg_info "Starting Scaffold services"

# Configure Neo4j health check and volumes
if [ -f /opt/scaffold/docker-compose.yaml ]; then
  msg_info "Configuring Neo4j health check"
  
  # Replace complex cypher-shell health check with simpler version
  # This avoids dependency on cypher-shell and makes health checks more reliable
  $STD sed -i '/cypher-shell/c\      test: ["CMD-SHELL", "curl -s --fail http:\/\/localhost:7474 || exit 1"]' /opt/scaffold/docker-compose.yaml
  $STD sed -i 's/interval: 5s/interval: 10s/' /opt/scaffold/docker-compose.yaml
  $STD sed -i 's/retries: 5/retries: 20/' /opt/scaffold/docker-compose.yaml
  $STD sed -i 's/timeout: 5s/timeout: 10s/' /opt/scaffold/docker-compose.yaml
  
  # Replace build section with image reference for scaffold-mcp service
  $STD sed -i '/^    build:/,/^    context:/d' /opt/scaffold/docker-compose.yaml
  $STD sed -i '/^  scaffold-mcp:/a\    image: ghcr.io/beer-bears/scaffold:latest' /opt/scaffold/docker-compose.yaml
  
  # Create Neo4j data and log directories with proper permissions
  mkdir -p /opt/scaffold/data/neo4j /opt/scaffold/logs/neo4j
  $STD chown -R 7474:7474 /opt/scaffold/data/neo4j || echo "Directory /opt/scaffold/data/neo4j not found, skipping chown"
  $STD chown -R 7474:7474 /opt/scaffold/logs/neo4j || echo "Directory /opt/scaffold/logs/neo4j not found, skipping chown"
fi

  # Start Scaffold services with retry logic
  echo "Starting Scaffold services"
  for i in {1..3}; do
    echo "Starting services (attempt $i of 3)"
    if $STD docker compose up -d; then
      echo "Scaffold services started successfully"
      break
    else
      echo "Attempt $i failed, retrying in 10 seconds..."
      echo "Checking container status..."
      $STD docker compose ps
      echo "Checking logs for neo4j container..."
      $STD docker compose logs neo4j 2>/dev/null || true
      sleep 10
    fi
  done

msg_info "Configuring Nginx"
cat <<EOF2 >/etc/nginx/conf.d/scaffold.conf
server {
    listen 80;
    server_name $LOCAL_IP;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    location /neo4j {
        proxy_pass http://localhost:7474;
        proxy_set_header Host $host;
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

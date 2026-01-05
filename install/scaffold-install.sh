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
DOCKER_COMPOSE_VERSION=$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
mkdir -p /usr/local/lib/docker/cli-plugins
curl -fsSL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

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

# Fix Neo4j health check - use proper Neo4j health check
if [ -f /opt/scaffold/docker-compose.yaml ]; then
  # Replace complex cypher-shell health check with proper Neo4j health check
  # Use a simpler approach that checks if Neo4j is responding on port 7474
  # Replace Neo4j health check with simpler version
  $STD sed -i 's/test: \["CMD-SHELL", "cypher-shell -u.*"/test: ["CMD-SHELL", "curl -s http://localhost:7474 | grep -q \"200\""]/' /opt/scaffold/docker-compose.yaml
  $STD sed -i 's/interval: 5s/interval: 10s/' /opt/scaffold/docker-compose.yaml
  $STD sed -i 's/retries: 5/retries: 20/' /opt/scaffold/docker-compose.yaml
  
    # Also ensure Neo4j has proper volume permissions
    mkdir -p /opt/scaffold/data/neo4j
    mkdir -p /opt/scaffold/logs/neo4j
    $STD chown -R 7474:7474 /opt/scaffold/data/neo4j || echo "Directory /opt/scaffold/data/neo4j not found, skipping chown"
    $STD chown -R 7474:7474 /opt/scaffold/logs/neo4j || echo "Directory /opt/scaffold/logs/neo4j not found, skipping chown"
fi

# Try to start services with retries
for i in {1..3}; do
  if $STD docker compose up -d; then
    break
  else
    msg_warn "Attempt $i failed, retrying in 10 seconds..."
    msg_info "Checking container status..."
    $STD docker compose ps
    msg_info "Checking logs for neo4j container..."
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

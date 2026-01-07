#!/usr/bin/env bash

# Source function library if FUNCTIONS_FILE_PATH is available
if [ -n "$FUNCTIONS_FILE_PATH" ]; then
  source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
  color
  verb_ip6
  catch_errors
  setting_up_container
  network_check
  update_os
else
  # Fallback for direct execution without FUNCTIONS_FILE_PATH
  echo "FUNCTIONS_FILE_PATH not set, using basic functions"
  msg_info() { echo "$1"; }
  msg_success() { echo "✅ $1"; }
  msg_warn() { echo "⚠️  $1" >&2; }
  msg_error() { echo "❌ $1" >&2; }
  msg_ok() { echo "✅ $1"; }
fi

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

# Import local IP if available, otherwise get it directly
if command -v import_local_ip >/dev/null 2>&1; then
  import_local_ip
else
  # Fallback: get IP directly
  LOCAL_IP=$(hostname -I | awk '{print $1}')
  if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="localhost"
  fi
fi

# Download scaffold configuration files
mkdir -p /opt/scaffold
cd /opt/scaffold

# Create docker-compose.yaml with correct image references
cat > docker-compose.yaml <<'EOF'
version: '3.8'
services:
  scaffold-mcp:
    image: ghcr.io/beer-bears/scaffold:latest
    container_name: scaffold-mcp-prod
    env_file:
      - .env
    tty: true
    ports:
      - "8000:8080"
    depends_on:
      - neo4j
    volumes:
      - ./codebase:/app/codebase

  chromadb:
    image: chromadb/chroma:1.0.13
    container_name: scaffold-chromadb
    restart: unless-stopped
    environment:
      - CHROMA_SERVER_HOST=0.0.0.0
      - CHROMA_SERVER_HTTP_PORT=8000
      - ALLOW_RESET=TRUE
    volumes:
      - chroma_data:/data

  neo4j:
    image: neo4j:5
    container_name: scaffold-neo4j
    restart: unless-stopped
    environment:
      - NEO4J_server_config_strict__validation_enabled=false
      - NEO4J_AUTH=none
      - NEO4J_USER=${NEO4J_USER:-neo4j}
      - NEO4J_PASSWORD=${NEO4J_PASSWORD:-password}
    volumes:
      - neo4j_data:/data
    ports:
      - "7474:7474"
      - "7687:7687"
    healthcheck:
      test: ["CMD-SHELL", "curl -s --fail http://localhost:7474 || exit 1"]
      interval: 10s
      timeout: 10s
      retries: 20
      start_period: 10s

volumes:
  chroma_data:
  neo4j_data:
EOF

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

msg_info "Docker Compose will pull all required images automatically"

msg_info "Starting Scaffold services"

# Create Neo4j data and log directories with proper permissions
mkdir -p /opt/scaffold/data/neo4j /opt/scaffold/logs/neo4j
$STD chown -R 7474:7474 /opt/scaffold/data/neo4j || echo "Directory /opt/scaffold/data/neo4j not found, skipping chown"
$STD chown -R 7474:7474 /opt/scaffold/logs/neo4j || echo "Directory /opt/scaffold/logs/neo4j not found, skipping chown"

  # Start Scaffold services with retry logic
  echo "Starting Scaffold services"
  for i in {1..5}; do
    echo "Starting services (attempt $i of 5)"
    if $STD docker compose up -d; then
      echo "Scaffold services started successfully"
      break
    else
      echo "Attempt $i failed, retrying in 15 seconds..."
      echo "Checking container status..."
      $STD docker compose ps 2>/dev/null || true
      echo "Checking logs for neo4j container..."
      $STD docker compose logs neo4j 2>/dev/null || true
      sleep 15
    fi
  done

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

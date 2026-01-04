#!/usr/bin/env bash

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing SearXNG dependencies"
cat <<EOF2 >/etc/apt/sources.list.d/backports.sources
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie-backports
Components: main
EOF2

msg_info "Updating package lists"
$STD apt update

msg_info "Installing system dependencies"
$STD apt install -y git curl python3 python3-pip python3-venv \
  python3-dev build-essential libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev wget libncurses5-dev libncursesw5-dev \
  xz-utils tk-dev libffi-dev liblzma-dev nginx ufw \
  nodejs npm redis-server

msg_info "Installing Node.js 20.x for MCP support"
$STD curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
$STD apt install -y nodejs

msg_info "Installing MCP SearXNG"
$STD npm install -g @mcp/searxng

msg_info "Setting up SearXNG from source"
$STD git clone https://github.com/searxng/searxng /usr/local/searxng/searxng-src
cd /usr/local/searxng/searxng-src

msg_info "Installing Python dependencies"
$STD python3 -m pip install --upgrade pip
$STD python3 -m pip install -r requirements.txt

msg_info "Configuring SearXNG"
$STD cp settings.yml settings.yml.bak

# Configure settings.yml
sed -i 's|^# server_port: 8080|server_port: 8886|' settings.yml
sed -i 's|^# bind_address: 127.0.0.1|bind_address: 0.0.0.0|' settings.yml

# Configure Redis for caching
cat <<EOF2 >> settings.yml

  # Redis configuration
  cache:
    name: searxng-redis
    url: redis://localhost:6379/0
EOF2

msg_info "Creating systemd service for SearXNG"
cat <<EOF2 >/etc/systemd/system/searxng.service
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
EOF2

msg_info "Creating systemd service for MCP SearXNG"
cat <<EOF2 >/etc/systemd/system/mcp-searxng.service
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
EOF2

msg_info "Configuring Nginx"
cat <<EOF2 >/etc/nginx/sites-available/searxng
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
EOF2

$STD ln -sf /etc/nginx/sites-available/searxng /etc/nginx/sites-enabled/
$STD rm /etc/nginx/sites-enabled/default

msg_info "Configuring firewall"
$STD ufw allow 8888/tcp
$STD ufw allow 3000/tcp
$STD ufw --force enable

msg_info "Starting services"
$STD systemctl daemon-reload
$STD systemctl enable searxng
$STD systemctl enable mcp-searxng
$STD systemctl enable redis
$STD systemctl start searxng
$STD systemctl start mcp-searxng
$STD systemctl start redis

msg_info "Configuring Nginx"
$STD systemctl restart nginx

motd_ssh
customize
cleanup_lxc

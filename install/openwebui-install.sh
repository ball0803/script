#!/usr/bin/env bash

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing OpenWebUI dependencies"
$STD apt install -y python3 python3-pip python3-venv \
  git curl build-essential libssl-dev nginx ufw

msg_info "Creating Python virtual environment"
$STD python3 -m venv /opt/openwebui
$STD chown -R root:root /opt/openwebui

msg_info "Installing OpenWebUI"
$STD /opt/openwebui/bin/pip install open-webui

msg_info "Configuring OpenWebUI service"
cat <<EOF > /etc/systemd/system/openwebui.service
[Unit]
Description=Open WebUI
After=network.target

[Service]
User=root
WorkingDirectory=/opt/openwebui
Environment="PATH=/opt/openwebui/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/opt/openwebui/bin/open-webui serve
Restart=always

[Install]
WantedBy=multi-user.target
EOF

if [[ "${var_ollama:-no}" == "yes" ]]; then
  msg_info "Installing Ollama"
  $STD curl -fsSL https://ollama.com/install.sh | sh
  $STD systemctl enable --now ollama
  
  msg_info "Pulling default model for Ollama"
  $STD ollama pull llama3
fi

msg_info "Configuring Nginx"
cat <<EOF > /etc/nginx/sites-available/openwebui
server {
    listen 3000;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

$STD ln -sf /etc/nginx/sites-available/openwebui /etc/nginx/sites-enabled/
$STD rm /etc/nginx/sites-enabled/default

msg_info "Configuring firewall"
$STD ufw allow 3000/tcp
if [[ "${var_ollama:-no}" == "yes" ]]; then
  $STD ufw allow 11434/tcp
fi
$STD ufw --force enable

msg_info "Starting services"
$STD systemctl daemon-reload
$STD systemctl enable openwebui
$STD systemctl start openwebui

if [[ "${var_ollama:-no}" == "yes" ]]; then
  $STD systemctl restart ollama
fi

$STD systemctl restart nginx

motd_ssh
customize
cleanup_lxc

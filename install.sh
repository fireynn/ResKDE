#!/usr/bin/env bash
set -eREPO_USER="fireynn"
REPO_NAME="ResKDE"
INSTALL_DIR="$HOME/.local/share/resKDE"
SERVICE_NAME="reskde"echo "=== resKDE Bot Installer ==="if ! command -v python3 &> /dev/null; then
echo "Error: python3 is not installed." >&2
exit 1
fiecho "To get a Telegram bot token, message @BotFather on Telegram (https://t.me/BotFather) and create a new bot."
read -p "Enter your Telegram Bot Token: " BOT_TOKENif [ -z "$BOT_TOKEN" ]; then
echo "Error: Token cannot be empty." >&2
exit 1
firead -p "Enter proxy URL if needed (e.g., socks5://127.0.0.1:2080 or leave blank): " PROXY_URLmkdir -p "$INSTALL_DIR"echo "Downloading bot files..."
curl -sL "https://github.com/${REPO_USER}/${REPO_NAME}/archive/refs/heads/main.tar.gz" | tar xz --strip-components=1 -C "$INSTALL_DIR"cd "$INSTALL_DIR"echo "BOT_TOKEN=$BOT_TOKEN" > .env
if [ -n "$PROXY_URL" ]; then
echo "PROXY_URL=$PROXY_URL" >> .env
fipython3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
if [ -f "requirements.txt" ]; then
pip install -r requirements.txt
fimkdir -p "$HOME/.config/systemd/user"
cat << EOF > "$HOME/.config/systemd/user/${SERVICE_NAME}.service"
[Unit]
Description=resKDE Telegram Bot Service
After=network.target[Service]
Type=simple
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/venv/bin/python${INSTALL_DIR}/main.py
Restart=always
RestartSec=5
EnvironmentFile=${INSTALL_DIR}/.env[Install]
WantedBy=default.target
EOFsystemctl --user daemon-reload
systemctl --user enable "${SERVICE_NAME}.service"
systemctl --user restart "${SERVICE_NAME}.service"echo "=== Installation completed successfully! ==="
echo "Manage the bot using: systemctl --user status ${SERVICE_NAME}"

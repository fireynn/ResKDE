#!/usr/bin/env bash
set -euo pipefail

REPO_USER="fireynn"
REPO_NAME="ResKDE"
INSTALL_DIR="$HOME/.local/share/resKDE"
SERVICE_NAME="reskde"

echo "=== resKDE Bot Installer ==="

if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is not installed." >&2
    exit 1
fi

echo "To get a Telegram bot token, message @BotFather on Telegram (https://t.me/BotFather) and create a new bot."
read -r -p "Enter your Telegram Bot Token: " BOT_TOKEN < /dev/tty

if [ -z "$BOT_TOKEN" ]; then
    echo "Error: Token cannot be empty." >&2
    exit 1
fi

read -r -p "Enter proxy URL if needed (e.g., socks5://127.0.0.1:2080 or leave blank): " PROXY_URL < /dev/tty

mkdir -p "$INSTALL_DIR"

echo "Downloading bot files..."
curl -sL "https://github.com/${REPO_USER}/${REPO_NAME}/archive/refs/heads/main.tar.gz" | tar xz --strip-components=1 -C "$INSTALL_DIR"

cd "$INSTALL_DIR"

echo "Creating .env configuration..."
echo "BOT_TOKEN=$BOT_TOKEN" > .env
if [ -n "$PROXY_URL" ]; then
    echo "PROXY_URL=$PROXY_URL" >> .env
fi

echo "Setting up Python virtual environment..."
rm -rf "$INSTALL_DIR/venv"
python3 -m venv "$INSTALL_DIR/venv"

VENV_PYTHON="$INSTALL_DIR/venv/bin/python"

echo "Upgrading pip..."
"$VENV_PYTHON" -m pip install --upgrade pip

# Поиск requirements.txt (на случай, если регистр букв отличается или файл пуст)
REQ_FILE="$INSTALL_DIR/requirements.txt"

if [ -f "$REQ_FILE" ]; then
    echo "Found requirements.txt. Contents:"
    cat "$REQ_FILE"
    echo "-----------------------------------"
    echo "Installing dependencies..."
    "$VENV_PYTHON" -m pip install --no-cache-dir -r "$REQ_FILE"
else
    echo "Error: requirements.txt was not found in $INSTALL_DIR!" >&2
    ls -la "$INSTALL_DIR" >&2
    exit 1
fi

echo "Creating systemd user service..."
mkdir -p "$HOME/.config/systemd/user"

cat << EOF > "$HOME/.config/systemd/user/${SERVICE_NAME}.service"
[Unit]
Description=resKDE Telegram Bot Service
After=network.target

[Service]
Type=simple
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/venv/bin/python ${INSTALL_DIR}/aiogram_run.py
Restart=always
RestartSec=5
EnvironmentFile=${INSTALL_DIR}/.env

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable "${SERVICE_NAME}.service"
systemctl --user restart "${SERVICE_NAME}.service"

echo "=== Installation completed successfully! ==="
echo "Manage the bot using: systemctl --user status ${SERVICE_NAME}"

#!/usr/bin/env bash
set -e

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
read -p "Enter your Telegram Bot Token: " BOT_TOKEN < /dev/tty

if [ -z "$BOT_TOKEN" ]; then
    echo "Error: Token cannot be empty." >&2
    exit 1
fi

read -p "Enter proxy URL if needed (e.g., socks5://127.0.0.1:2080 or leave blank): " PROXY_URL < /dev/tty

# Создаем и очищаем целевую директорию перед распаковкой
mkdir -p "$INSTALL_DIR"

echo "Downloading bot files..."
curl -sL "https://github.com/${REPO_USER}/${REPO_NAME}/archive/refs/heads/main.tar.gz" | tar xz --strip-components=1 -C "$INSTALL_DIR"

# Переходим строго в папку установки
cd "$INSTALL_DIR"

echo "Creating .env configuration..."
echo "BOT_TOKEN=$BOT_TOKEN" > .env
if [ -n "$PROXY_URL" ]; then
    echo "PROXY_URL=$PROXY_URL" >> .env
fi

echo "Setting up Python virtual environment..."
python3 -m venv venv

# Обновляем pip с явным указанием пути к venv
"$INSTALL_DIR/venv/bin/python" -m pip install --upgrade pip

# Установка зависимостей
if [ -f "requirements.txt" ]; then
    echo "Installing dependencies from requirements.txt..."
    "$INSTALL_DIR/venv/bin/pip" install -r requirements.txt
else
    echo "Error: requirements.txt was not found in $INSTALL_DIR!" >&2
    echo "Contents of $INSTALL_DIR:" >&2
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

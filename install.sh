#!/usr/bin/env bash
set -euo pipefail

REPO_USER="fireynn"
REPO_NAME="ResKDE"
INSTALL_DIR="$HOME/.local/share/resKDE"
BIN_DIR="$HOME/.local/bin"
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

read -r -p "Enter proxy URL if needed (e.g., socks5://127.0.0.1:2080 or leave blank): " PROXY_URL < /dev/tty || true
read -r -p "Enter the Telegram user ID (if left blank, enter the /id command to save id to .env): " IDUSER < /dev/tty || true
mkdir -p "$INSTALL_DIR"

echo "Downloading bot files..."
curl -sL "https://github.com/${REPO_USER}/${REPO_NAME}/archive/refs/heads/main.tar.gz" | tar xz --strip-components=1 -C "$INSTALL_DIR"

cd "$INSTALL_DIR"

echo "Creating .env configuration..."
echo "BOT_TOKEN=$BOT_TOKEN" > .env
if [ -n "${PROXY_URL:-}" ]; then
    echo "PROXY_URL=$PROXY_URL" >> .env
fi
if [ -n "${IDUSER:-}" ]; then
    echo "IDUSER=$IDUSER" >> .env
fi

echo "Setting up Python virtual environment..."
rm -rf "$INSTALL_DIR/venv"
python3 -m venv "$INSTALL_DIR/venv"

VENV_PYTHON="$INSTALL_DIR/venv/bin/python"

echo "Upgrading pip..."
"$VENV_PYTHON" -m pip install --upgrade pip

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

echo "Creating systemd user service with memory limits..."
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
MemoryHigh=60M
MemoryMax=80M

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable "${SERVICE_NAME}.service"
systemctl --user restart "${SERVICE_NAME}.service"

echo "Installing CLI manager (reskde binary)..."
mkdir -p "$BIN_DIR"

cat << 'EOF' > "$BIN_DIR/reskde"
#!/usr/bin/env bash

SERVICE="reskde"
INSTALL_DIR="$HOME/.local/share/resKDE"
ENV_FILE="$INSTALL_DIR/.env"

show_help() {
    echo "Usage: reskde <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  start                Start the bot service"
    echo "  stop                 Stop the bot service"
    echo "  restart              Restart the bot service"
    echo "  status               Check bot service status"
    echo "  logs                 Stream live bot logs (journalctl)"
    echo "  set <KEY> <VALUE>    Set or update any environment variable in .env (e.g., reskde set IDUSER 1894123)"
    echo "  get <KEY>            Get the value of an environment variable"
    echo "  show                 Show all current variables in .env"
    echo "  help                 Display this help message"
}

if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
    start)
        systemctl --user start "$SERVICE"
        echo "resKDE bot started."
        ;;
    stop)
        systemctl --user stop "$SERVICE"
        echo "resKDE bot stopped."
        ;;
    restart)
        systemctl --user restart "$SERVICE"
        echo "resKDE bot restarted."
        ;;
    status)
        systemctl --user status "$SERVICE"
        ;;
    logs)
        journalctl --user -u "$SERVICE" -f
        ;;
    set)
        KEY="$1"
        VAL="$2"
        if [ -z "$KEY" ] || [ -z "$VAL" ]; then
            echo "Error: Missing key or value."
            echo "Usage: reskde set <KEY> <VALUE>"
            exit 1
        fi

        [ ! -f "$ENV_FILE" ] && touch "$ENV_FILE"

        if grep -q "^${KEY}=" "$ENV_FILE"; then
            sed -i "s/^${KEY}=.*/${KEY}=${VAL}/" "$ENV_FILE"
        else
            echo "${KEY}=${VAL}" >> "$ENV_FILE"
        fi

        echo "Successfully updated ${KEY} = ${VAL} in ${ENV_FILE}"
        systemctl --user restart "$SERVICE"
        echo "Bot restarted to apply changes."
        ;;
    get)
        KEY="$1"
        if [ -z "$KEY" ]; then
            echo "Error: Please specify the key."
            echo "Usage: reskde get <KEY>"
            exit 1
        fi
        if [ -f "$ENV_FILE" ]; then
            grep "^${KEY}=" "$ENV_FILE" || echo "${KEY} is not set."
        else
            echo ".env file does not exist."
        fi
        ;;
    show)
        if [ -f "$ENV_FILE" ]; then
            echo "=== Contents of $ENV_FILE ==="
            cat "$ENV_FILE"
        else
            echo ".env file does not exist."
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $COMMAND"
        echo "Run 'reskde help' for available commands."
        exit 1
        ;;
esac
EOF

chmod +x "$BIN_DIR/reskde"

echo "=== Installation completed successfully! ==="
echo "You can now manage the bot using the 'reskde' command anywhere (e.g., reskde status)"

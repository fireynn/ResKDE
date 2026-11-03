
#!/usr/bin/env bash
set -euo pipefail

REPO_USER="fireynn"
REPO_NAME="ResKDE"
INSTALL_DIR="$HOME/.local/share/resKDE"
BIN_DIR="$HOME/.local/bin"
SERVICE_NAME="reskde"

echo "=== resKDE Bot Installer / Updater ==="

if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is not installed." >&2
    exit 1
fi

# Проверяем, существует ли уже установленный бот
if [ -d "$INSTALL_DIR" ]; then
    echo "Existing installation found at $INSTALL_DIR. Updating files..."

    # Сохраняем .env во временный файл перед обновлением
    if [ -f "$INSTALL_DIR/.env" ]; then
        cp "$INSTALL_DIR/.env" /tmp/reskde_env_backup
    fi

    # Скачиваем свежую версию архива во временную папку
    TEMP_DIR=$(mktemp -d)
    curl -sL "https://github.com/${REPO_USER}/${REPO_NAME}/archive/refs/heads/main.tar.gz" | tar xz --strip-components=1 -C "$TEMP_DIR"

    # Переносим новые файлы, не затирая папку venv и .env
    rsync -av --exclude='venv' --exclude='.env' "$TEMP_DIR/" "$INSTALL_DIR/"
    rm -rf "$TEMP_DIR"

    # Восстанавливаем .env на случай, если он был перезаписан
    if [ -f /tmp/reskde_env_backup ]; then
        mv /tmp/reskde_env_backup "$INSTALL_DIR/.env"
    fi

    cd "$INSTALL_DIR"

    # Обновляем зависимости, если изменился requirements.txt
    VENV_PYTHON="$INSTALL_DIR/venv/bin/python"
    if [ -f "$INSTALL_DIR/requirements.txt" ]; then
        echo "Updating dependencies..."
        "$VENV_PYTHON" -m pip install --upgrade pip
        "$VENV_PYTHON" -m pip install --no-cache-dir -r "$INSTALL_DIR/requirements.txt"
    fi

else
    # Первичная установка (если папки нет)
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
    echo "IDUSER=${IDUSER:-}" >> .env

    echo "Setting up Python virtual environment..."
    python3 -m venv "$INSTALL_DIR/venv"

    VENV_PYTHON="$INSTALL_DIR/venv/bin/python"

    echo "Upgrading pip..."
    "$VENV_PYTHON" -m pip install --upgrade pip

    REQ_FILE="$INSTALL_DIR/requirements.txt"

    if [ -f "$REQ_FILE" ]; then
        echo "Installing dependencies..."
        "$VENV_PYTHON" -m pip install --no-cache-dir -r "$REQ_FILE"
    else
        echo "Error: requirements.txt was not found in $INSTALL_DIR!" >&2
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
fi

echo "Updating CLI manager (reskde binary)..."
mkdir -p "$BIN_DIR"

cat << 'EOF' > "$BIN_DIR/reskde"
#!/usr/bin/env bash

SERVICE="reskde"
INSTALL_DIR="$HOME/.local/share/resKDE"
BIN_FILE="$HOME/.local/bin/reskde"
SERVICE_FILE="$HOME/.config/systemd/user/${SERVICE}.service"
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
    echo "  uninstall            Completely remove the bot, service, and CLI tool"
    echo "  set <KEY> <VALUE>    Set or update any environment variable in .env"
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
    uninstall)
        echo "=== Uninstalling resKDE Bot ==="

        echo "Stopping and disabling systemd service..."
        systemctl --user stop "$SERVICE" 2>/dev/null || true
        systemctl --user disable "$SERVICE" 2>/dev/null || true

        echo "Removing systemd service file..."
        rm -f "$SERVICE_FILE"
        systemctl --user daemon-reload

        echo "Removing installation directory ($INSTALL_DIR)..."
        rm -rf "$INSTALL_DIR"

        echo "Removing CLI binary..."
        rm -f "$BIN_FILE"

        echo "=== Uninstallation completed successfully! ==="
        exit 0
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

# Перезапуск службы для применения обновленного кода
systemctl --user daemon-reload
systemctl --user restart "${SERVICE_NAME}.service"

echo "=== Operation completed successfully! ==="
echo "The bot has been updated and restarted. Use 'reskde status' to check."

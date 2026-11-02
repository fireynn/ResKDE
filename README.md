# resKDE 🤖🔄

[English](#english) | [Русский](#russian)

---

<a name="english"></a>
## 🇬🇧 English

`resKDE` is an asynchronous Telegram bot designed to hard-restart and recover the KDE Plasma graphical environment (supporting both Wayland and X11) even when the session or window manager is completely frozen.

### Features
* **Non-blocking Execution:** Built with Python `asyncio` to ensure the bot remains responsive during system-level commands.
* **Smart Thawing & Recovery:** Automatically sends continuation signals (`-CONT`) to frozen composers (`kwin_wayland`, `kwin_x11`) before forcing a restart.
* **Systemd Integration:** Cleanly interacts with user-level systemd services (`plasma-plasmashell.service`) with built-in safeguards and timeouts to prevent hanging.
* **Easy Installation:** Automated interactive installer script via `curl`.

### Installation

Run the following command in your terminal to install the bot:

```bash
curl -sL https://raw.githubusercontent.com/fireynn/ResKDE/main/install.sh -o install.sh; and bash install.sh; and rm install.sh
```

### Management

You can manage the bot service using standard systemd user commands:
* Check status: `systemctl --user status reskde`
* View logs: `journalctl --user -u reskde -e`
* Restart bot: `systemctl --user restart reskde`

---

<a name="russian"></a>
## 🇷🇺 Русский

`resKDE` — это асинхронный Telegram-бот, предназначенный для принудительного перезапуска и восстановления графического окружения KDE Plasma (с поддержкой Wayland и X11) даже в тех случаях, когда сеанс или оконный менеджер полностью зависли.

### Возможности
* **Асинхронность:** Написан с использованием Python `asyncio`, что гарантирует отзывчивость бота во время выполнения системных команд.
* **Умная разморозка:** Перед перезапуском автоматически отправляет сигналы продолжения работы (`-CONT`) замороженным композиторам (`kwin_wayland`, `kwin_x11`).
* **Интеграция с systemd:** Корректно взаимодействует с пользовательскими службами `plasma-plasmashell.service` с защитными таймаутами против зависаний.
* **Простая установка:** Автоматический интерактивный скрипт установки через `curl`.

### Установка

Выполните следующую команду в терминале для установки бота:

```bash
curl -sL https://raw.githubusercontent.com/fireynn/ResKDE/main/install.sh -o install.sh; and bash install.sh; and rm install.sh
```

### Управление

Управлять службой бота можно с помощью стандартных пользовательских команд systemd:
* Проверить статус: `systemctl --user status reskde`
* Посмотреть логи: `journalctl --user -u reskde -e`
* Перезапустить бота: `systemctl --user restart reskde`

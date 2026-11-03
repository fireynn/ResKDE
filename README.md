# resKDE 🤖🔄

[English](#english) | [Русский](#russian)

---

<a name="english"></a>
## 🇬🇧 English

`resKDE` is an asynchronous Telegram bot designed to hard-restart and recover the KDE Plasma graphical environment (supporting both Wayland and X11) even when the session or window manager is completely frozen.

### Features
* **Non-blocking Execution:** Built with `aiogram 3` and `asyncio` to remain responsive during system commands.
* **Smart Thawing & Recovery:** Sends continuation signals (`-CONT`) to frozen composers (`kwin_wayland`, `kwin_x11`) before forcing a restart.
* **Systemd & Resource Limits:** Configured as a `systemd` user service with resource limits (`MemoryMax=80M`, `MemoryHigh=60M`).
* **Interactive CLI Management Tool:** Includes a built-in `reskde` binary for service control, variable management, and full uninstallation.
* **Auto Update & Seamless Setup:** Supports clean installation as well as updating existing setups without losing configuration (`.env`).
* **Dynamic Authorization:** Allows initializing without an ID and dynamically binding user permissions via the `/id` command.

### Installation & Updates

Run the following command in your terminal to install or update the bot:

**Bash:**
```bash
bash <(curl -sSL https://raw.githubusercontent.com/fireynn/ResKDE/main/install.sh)
```

**Fish:**
```bash
bash (curl -sSL https://raw.githubusercontent.com/fireynn/ResKDE/main/install.sh | psub)
```

### Management CLI (`reskde`)

Manage the bot using the dedicated `reskde` command anywhere in your system:

* **Check status:** `reskde status`
* **Stream live logs:** `reskde logs`
* **Start / Stop / Restart:** `reskde start` | `reskde stop` | `reskde restart`
* **Manage environment variables:** 
  * `reskde set IDUSER <your_telegram_id>`
  * `reskde get IDUSER`
  * `reskde show`
* **Uninstall bot completely:** `reskde uninstall`

---

<a name="russian"></a>
## 🇷🇺 Русский

`resKDE` — это асинхронный Telegram-бот, предназначенный для принудительного перезапуска и восстановления графического окружения KDE Plasma (с поддержкой Wayland и X11) даже в тех случаях, когда сеанс или оконный менеджер полностью зависли.

### Возможности
* **Асинхронность:** Написан с использованием `aiogram 3` и `asyncio`, что гарантирует отзывчивость бота во время выполнения системных команд.
* **Умная разморозка:** Перед перезапуском автоматически отправляет сигналы продолжения работы (`-CONT`) замороженным композиторам (`kwin_wayland`, `kwin_x11`).
* **Ограничение ресурсов:** Запускается как пользовательская служба `systemd` с лимитами памяти (`MemoryMax=80M`, `MemoryHigh=60M`).
* **Управляющая CLI-утилита:** Поставляется с бинарником `reskde` для удобного управления службой, переменными окружения и полным удалением.
* **Бесшовное обновление:** Поддерживает как чистую установку, так и обновление существующих файлов бота без перезаписи конфигурации `.env`.
* **Динамическая регистрация:** Позволяет пропустить ввод ID при установке и зарегистрировать свой Telegram ID на лету командой `/id`.

### Установка и обновление

Выполните команду в терминале для установки или обновления бота:

**Для Bash:**
```bash
bash <(curl -sSL https://raw.githubusercontent.com/fireynn/ResKDE/main/install.sh)
```

**Для Fish:**
```bash
bash (curl -sSL https://raw.githubusercontent.com/fireynn/ResKDE/main/install.sh | psub)
```

### Управление через CLI (`reskde`)

Управлять ботом можно с помощью встроенной утилиты `reskde` из любой точки системы:

* **Проверить статус:** `reskde status`
* **Смотреть логи в реальном времени:** `reskde logs`
* **Запуск / Остановка / Перезапуск:** `reskde start` | `reskde stop` | `reskde restart`
* **Управление `.env` переменными:**
  * `reskde set IDUSER <ваш_telegram_id>`
  * `reskde get IDUSER`
  * `reskde show`
* **Полное удаление бота и службы:** `reskde uninstall`
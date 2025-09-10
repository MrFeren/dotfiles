#!/bin/bash

# Создаем временный файл для меню
MENU_FILE=$(mktemp)

# Получаем список сетей и формируем меню
nmcli -f SSID,SIGNAL device wifi list | \
  awk 'NR>1 {if ($1 != "--") print $0}' | \
  sort -k2 -nr | \
  awk '{print $1 " (" $2 "%)"}' | \
  head -10 > "$MENU_FILE"

# Добавляем системные команды в меню
echo "▸ Отключиться от сети" >> "$MENU_FILE"
echo "▸ Открыть настройки сети" >> "$MENU_FILE"
echo "▸ Терминал сетевых команд" >> "$MENU_FILE"

# Запускаем wofi
CHOICE=$(wofi --dmenu --prompt "Сети" --style ~/.config/wofi/style.css < "$MENU_FILE")

# Обрабатываем выбор
case "$CHOICE" in
    "▸ Отключиться от сети")
        nmcli device disconnect $(nmcli -t -f DEVICE,TYPE device | grep -E ":wifi|:ethernet" | cut -d: -f1)
        ;;
    "▸ Открыть настройки сети")
        nm-connection-editor
        ;;
    "▸ Терминал сетевых команд")
        kitty -e nmtui
        ;;
    *)
        if [ -n "$CHOICE" ]; then
            # Извлекаем имя сети (без уровня сигнала)
            SSID=$(echo "$CHOICE" | sed 's/ (.*//')
            # Подключаемся к выбранной сети
            nmcli device wifi connect "$SSID"
        fi
        ;;
esac

# Удаляем временный файл
rm "$MENU_FILE"

#!/bin/bash

LOG="/var/log/tg_system_update.log"
: > "$LOG"
exec >> "$LOG" 2>&1

echo "📦 Оновлення системи — $(date)"
apt update && apt upgrade -y && apt autoremove -y
flatpak update -y
snap refresh || echo "⚠️ snap недоступний"

echo "✅ Оновлення завершено"

# Надсилання
TEXT="📦 Оновлення системи — $(date '+%F %T')\n\n$(tail -c 3500 "$LOG")"
/root/scripts/send_telegram.sh "$TEXT" "HTML"

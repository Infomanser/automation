#!/bin/bash

# Визначення PATH, щоб у cron були доступні всі команди
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Лог-файли
LOG_FILE="/var/log/health.log"
CRON_LOG="/var/log/health-cron.log"
TG_LOG="/var/log/health-telegram.log"

# Логування середовища cron для діагностики
{
  echo "=== Cron environment at $(date) ==="
  env
  echo
} >> "$CRON_LOG"

# Очистка основного лог-файлу
: > "$LOG_FILE"

# Перенаправлення всього виводу в основний лог
exec >> "$LOG_FILE" 2>&1

echo "🩺 Стан системи — $(date)"
echo
echo "⏱ Uptime:"
uptime
echo
echo "💾 Диск (/):"
df -h /
echo
echo "🧠 Пам’ять:"
free -h
echo
echo "🖥 Температури:"
{
  echo "CPU:      $(sensors | grep 'CPU:' | awk '{print $2}')"
  echo "GPU:      $(sensors | grep 'edge:' | awk '{print $2}')"
  echo "SSD:      $(sensors | grep 'Composite:' | awk '{print $2}')"
  echo "RAM:      $(sensors | grep 'SODIMM:' | awk '{print $2}')"
  echo "Ambient:  $(sensors | grep 'Ambient:' | awk '{print $2}')"
}
echo
echo "⬆️ Доступні оновлення (APT):"
apt list --upgradable 2>/dev/null | grep -v "Listing..."
echo

# Завантаження змінних середовища з .env
source /root/scripts/.env

# Відправка повідомлення у Telegram і логування відповіді
response=$(curl -sS -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
  -d chat_id="$TELEGRAM_CHAT_ID" \
  -d parse_mode="Markdown" \
  -d text="$(sed 's/&/\\&/g; s/</\\</g; s/>/\\>/g' "$LOG_FILE")")

echo "Telegram response: $response" >> "$TG_LOG"

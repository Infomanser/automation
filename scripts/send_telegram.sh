#!/bin/bash

# Використання:
# ./send_telegram.sh "повідомлення" [parse_mode]

TEXT="$1"
MODE="$2"
source /root/scripts/.env
TG_LOG="/var/log/telegram.log"

# Якщо не вказано режим — не додаємо parse_mode
USE_PARSE_MODE=false
if [ -n "$MODE" ]; then
    USE_PARSE_MODE=true
fi

# Якщо вказано MarkdownV2 — екрануємо
if [ "$MODE" = "MarkdownV2" ]; then
    escape_md() {
        echo "$1" | sed -E 's/([][_*()~`>#+=|{}.!-])/\\\1/g'
    }
    TEXT=$(escape_md "$TEXT")
fi

# Відправка
if $USE_PARSE_MODE; then
    response=$(curl -sS -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
      -d chat_id="$TELEGRAM_CHAT_ID" \
      -d parse_mode="$MODE" \
      --data-urlencode "text=$TEXT")
else
    response=$(curl -sS -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
      -d chat_id="$TELEGRAM_CHAT_ID" \
      --data-urlencode "text=$TEXT")
fi

echo "Telegram response: $response" >> "$TG_LOG"

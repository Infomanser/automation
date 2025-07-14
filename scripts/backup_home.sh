#!/bin/bash

BACKUP_DIR="/mnt/backup"
SRC_DIR="/home"
LOG_FILE="/var/log/backup_home.log"

# Очистка логу
: > "$LOG_FILE"
exec >> "$LOG_FILE" 2>&1
echo "🔄 Бекап /home — $(date)"

# Перевірка монтування
if mountpoint -q "$BACKUP_DIR"; then
    rsync -a --delete \
        --exclude='.cache/' \
        --exclude='*/.cache/' \
        "$SRC_DIR"/ "$BACKUP_DIR"

    RSYNC_EXIT_CODE=$?

    if [ "$RSYNC_EXIT_CODE" -eq 0 ]; then
        echo "✅ Бекап завершено успішно"
        BACKUP_STATUS="✅ Резервне копіювання /home завершено"
    else
        echo "⚠️ rsync завершився з помилкою (код: $RSYNC_EXIT_CODE)"
        BACKUP_STATUS="⚠️ Помилка: rsync завершився з кодом $RSYNC_EXIT_CODE"
    fi
else
    echo "❌ Помилка: $BACKUP_DIR не змонтовано"
    BACKUP_STATUS="❌ Помилка: $BACKUP_DIR не змонтовано"
fi

# Змінна з поточною датою
NOW="$(date '+%F %T')"

# Готуємо вміст
tail -c 3500 "$LOG_FILE" > "$TMP"
TEXT="📦 $BACKUP_STATUS"$'\n'"Дата: $NOW"$'\n\n'"$(cat "$TMP")"

# Відправка повідомлення
/root/scripts/send_telegram.sh "$TEXT"

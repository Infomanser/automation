#!/bin/bash

LOG_FILE="/var/log/sys_cleanup.log"
TMP="/tmp/sys_cleanup.tmp"

: > "$LOG_FILE"
exec >> "$LOG_FILE" 2>&1

echo "🧹 Початок очищення системи — $(date)"

# 1. Очистка старих ядер (залишити 2 останні)
if command -v purge-old-kernels >/dev/null 2>&1; then
    echo "🧼 Очищуємо старі ядра (залишаємо 2 останні)..."
    purge-old-kernels -y --keep 2
else
    echo "⚠️ purge-old-kernels не встановлено — пропускаємо очистку ядер"
fi

# 2. Видалення непотрібних залежностей
echo "🧼 Виконуємо apt autoremove, autoclean, clean..."
apt autoremove -y
apt autoclean -y
apt clean -y

# 3. Очистка кешу Flatpak
if command -v flatpak >/dev/null 2>&1; then
    echo "🧼 Очищуємо кеш Flatpak..."
    flatpak uninstall --unused -y 2>/dev/null
    rm -rf ~/.cache/flatpak
else
    echo "⚠️ flatpak не встановлено — пропускаємо очистку кешу Flatpak"
fi

# 4. Очищення журналів journalctl старших за 14 днів
echo "🧼 Очищення системних журналів старших за 14 днів..."
journalctl --vacuum-time=14d

# 5. Очищення великих логів (>10МБ) у /var/log (архівування та обнулення)
echo "🧼 Очищаємо великі логи (>10МБ) у /var/log..."
find /var/log -type f -size +10M | while read -r logfile; do
    echo "🗑️ Очищаємо $logfile"
    # Архівуємо і обнуляємо файл
    gzip -c "$logfile" > "$logfile.$(date '+%F_%H%M%S').gz" && : > "$logfile"
done

echo "✅ Прибирання завершено: $(date)"

# Готуємо логи до відправки
tail -c 3500 "$LOG_FILE" > "$TMP"
TEXT="🧹 Очищення системи — $(date '+%F %T')\n\n$(cat "$TMP")"

/root/scripts/send_telegram.sh "$TEXT"

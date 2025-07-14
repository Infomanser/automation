#!/bin/bash

echo "🚀 Starting to install the playbook..."

# --- 1. Copy scripts
echo "📁 Copy the scripts to /root/scripts/"
mkdir -p /root/scripts
cp -ru ./scripts/* /root/scripts/
chmod +x /root/scripts/*.sh

# --- 2. Copy systemd units
echo "🧩 Copying systemd units..."
cp -u ./systemd/*.service /etc/systemd/system/
cp -u ./systemd/*.timer /etc/systemd/system/

# --- 3. Rebooting systemd
echo "🔄 Rebooting systemd..."
systemctl daemon-reexec
systemctl daemon-reload

# --- 4. Enable Timers
echo "⏱️  Activate the timers..."
systemctl enable --now sys_cleanup.timer
systemctl enable --now system_update.timer

echo "🌡️ Installing sensors and configuring..."

# --- 5. Installing packages
apt update && apt install -y lm-sensors hddtemp

# --- 6. Launch automatic sensor detection
echo "🔍 Detecting available sensors (non-interactive)..."
yes | sensors-detect > /dev/null

# --- 7. Enable module autoload (may not be required for some systems)
systemctl enable --now kmod 2>/dev/null || true

echo "🛠️ You can manually rename sensors in /etc/sensors3.conf if needed"
echo "   Examples:"
echo '     label temp1 "CPU:"'
echo '     label temp2 "GPU:"'
echo '     label temp3 "SSD:"'
echo "   For detailed config, run: sensors-detect --auto"
# --- 8. Setup cron-jobs
echo "📆 Add tasks to cron..."
( crontab -l 2>/dev/null; echo "30 18 * * 5 /root/scripts/backup_home.sh >> /var/log/backuper-cron.log 2>&1" ) | sort -u | crontab -
( crontab -l 2>/dev/null; echo "59 3,7,11,15,18,23 * * * /root/scripts/health.sh >> /var/log/health-cron.log 2>&1" ) | sort -u | crontab -

# --- 9. Creating an .env if it missing
ENV_FILE="/root/scripts/.env"
if [[ ! -f "$ENV_FILE" ]]; then
	echo "🛡️  Creating an .env if it missing"
	cat <<EOF > "$ENV_FILE"
TELEGRAM_TOKEN="your_token_here"
TELEGRAM_CHAT_ID="your_chat_id_here"
EOF
	echo "⚠️  Fill in the /root/scripts/.env file before running the scripts!"
else
	echo "🔐 An .env file already exist - skipped"
fi

echo "✅ Installing is done!"
echo
echo "📋 Active systemd timers:"
systemctl list-timers --no-pager --all | grep -E 'sys_cleanup|system_update'

echo
echo "📋 Current crontab:"
crontab -l

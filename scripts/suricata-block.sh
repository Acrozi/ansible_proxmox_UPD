#!/bin/bash

# Kontrollera att nft och grep är installerade
command -v nft >/dev/null 2>&1 || { echo >&2 "nft is required but it's not installed. Aborting."; exit 1; }
command -v grep >/dev/null 2>&1 || { echo >&2 "grep is required but it's not installed. Aborting."; exit 1; }

# Kontrollera om loggfilen finns
LOGFILE="/var/log/suricata/fast.log"
if [ ! -f "$LOGFILE" ]; then
  echo "Log file $LOGFILE does not exist. Aborting."
  exit 1
fi

# Kontrollera om nftables blocklist finns
if ! nft list table inet filter | grep -q 'bruteforce_blocklist'; then
  echo "The blocklist 'bruteforce_blocklist' does not exist in nftables. Please create it first."
  exit 1
fi

# Lägg till IP-adresser som detekteras av Suricata till nftables blocklist
tail -F "$LOGFILE" | grep --line-buffered "SSH Brute Force Attempt" | while read -r line; do
  # Extrahera käll-IP-adressen (den första IP:en)
  IP=$(echo "$line" | awk -F'->' '{print $1}' | awk '{print $NF}' | cut -d':' -f1)

  # Validera IP-adressen
  if [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Kontrollera om IP redan är i blocklistan
    if nft list ruleset | grep -q "$IP"; then
      echo "$IP is already in the blocklist"
      continue
    fi
    attempts["$IP"]=$((attempts["$IP"] + 1))
    if [ "${attempts[$IP]}" -ge 5 ]; then
      nft add element inet filter bruteforce_blocklist { $IP timeout 1h }
      echo "Added $IP to blocklist after 5 failed attempts"
      unset attempts["$IP"]
    else
      echo "$IP has ${attempts[$IP]} failed attempts"
    fi
  else
    echo "Invalid IP address detected: $IP"
  fi
done

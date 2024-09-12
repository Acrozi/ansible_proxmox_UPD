#!/bin/bash

# Variabler
PVE_HOST="{{ pve_host }}"
PVE_USER="{{ pve_user }}"
PVE_PASS="{{ pve_pass }}"
NODE="s1"
SNAPSHOT_NAME="snapshot_$(date +%Y%m%d)"
DAYS_TO_KEEP=7
VM_IDS=("300" "301" "302" "303")  # Lista över VM-ID:n

for VMID in "${VM_IDS[@]}"; do
    echo "Creating snapshot for VMID $VMID..."

    # Generera autentiseringstoken
    PVE_AUTH_COOKIE=$(curl -s -k -d "username=$PVE_USER&password=$PVE_PASS&realm=pam" https://$PVE_HOST:8006/api2/json/access/ticket | jq -r ".data.ticket")
    PVE_CSRF_TOKEN=$(curl -s -k -d "username=$PVE_USER&password=$PVE_PASS&realm=pam" https://$PVE_HOST:8006/api2/json/access/ticket | jq -r ".data.CSRFPreventionToken")

    # Skapa snapshot
    curl -s -k -X POST https://$PVE_HOST:8006/api2/json/nodes/$NODE/lxc/$VMID/snapshot \
    -H "Cookie: PVEAuthCookie=$PVE_AUTH_COOKIE" \
    -H "CSRFPreventionToken: $PVE_CSRF_TOKEN" \
    -d "snapname=$SNAPSHOT_NAME"

    echo "Snapshot $SNAPSHOT_NAME created for VMID $VMID."

    # Hämta lista på snapshots och radera äldre än DAYS_TO_KEEP
    SNAPSHOTS=$(curl -s -k -X GET https://$PVE_HOST:8006/api2/json/nodes/$NODE/lxc/$VMID/snapshot \
    -H "Cookie: PVEAuthCookie=$PVE_AUTH_COOKIE" \
    -H "CSRFPreventionToken: $PVE_CSRF_TOKEN")

    # Loopa över snapshots och radera de som är äldre än DAYS_TO_KEEP
    current_date=$(date +%s)
    cutoff_date=$(($current_date - ($DAYS_TO_KEEP * 86400)))

    echo "$SNAPSHOTS" | jq -r '.data[] | select(.snaptime < '$cutoff_date') | .name' | while read snapname; do
        curl -s -k -X DELETE https://$PVE_HOST:8006/api2/json/nodes/$NODE/lxc/$VMID/snapshot/$snapname \
        -H "Cookie: PVEAuthCookie=$PVE_AUTH_COOKIE" \
        -H "CSRFPreventionToken: $PVE_CSRF_TOKEN"
        echo "Deleted snapshot: $snapname"
    done
done

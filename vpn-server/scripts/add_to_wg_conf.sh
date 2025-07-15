!/bin/bash

PRIVATE_KEY=$1
USERNAME=$2
PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey)

WG_CONF="/etc/wireguard/wg0.conf"

# Проверка существования PublicKey
if grep -q "PublicKey = $PUBLIC_KEY" "$WG_CONF"; then
  CLIENT_IP=$(grep -A 1 "PublicKey = $PUBLIC_KEY" "$WG_CONF" | grep "AllowedIPs" | awk '{print $3}')
else
  LAST_IP=$(grep -oP 'AllowedIPs = 10\.0\.0\.\K\d+' "$WG_CONF" | sort -n | tail -n 1)
  NEW_IP=$((LAST_IP + 1))
  [ -z "$LAST_IP" ] && NEW_IP=2
  CLIENT_IP="10.0.0.$NEW_IP/32"
  echo -e "\n[Peer]\nPublicKey = $PUBLIC_KEY\nAllowedIPs = $CLIENT_IP" >> "$WG_CONF"
fi

wg-quick down wg0 && wg-quick up wg0
echo "{\"username\":\"$USERNAME\",\"clientIp\":\"$CLIENT_IP\"}"
#!/bin/sh
set -e

echo "Starting entrypoint"

if [ -z "$DANTE_USER" ] || [ -z "$DANTE_PASS" ]; then
  echo "ERROR: DANTE_USER or DANTE_PASS is not set"
  exit 1
fi

echo "Creating user..."
useradd -m -s /bin/bash "$DANTE_USER" || true
echo "$DANTE_USER:$DANTE_PASS" | chpasswd
id "$DANTE_USER"

echo "Detecting outbound interface..."
# Try multiple methods to detect the external interface
EXTERNAL_IFACE=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}')

# Fallback: try to find the default interface
if [ -z "$EXTERNAL_IFACE" ]; then
  EXTERNAL_IFACE=$(ip route | grep default | awk '{print $5; exit}')
fi

# Fallback: use eth0 as default for containers
if [ -z "$EXTERNAL_IFACE" ]; then
  EXTERNAL_IFACE="eth0"
  echo "WARNING: Could not detect interface, using default: $EXTERNAL_IFACE"
else
  echo "Using external interface: $EXTERNAL_IFACE"
fi

# Use PORT environment variable for SOCKS proxy, or default to 1080
SOCKS_PORT=${PORT:-1080}
echo "Using SOCKS port: $SOCKS_PORT"

# Replace placeholders in config
sed -e "s/__EXTERNAL_IFACE__/$EXTERNAL_IFACE/" \
    -e "s/port = 1080/port = $SOCKS_PORT/" \
  /etc/danted.conf.template > /etc/danted.conf

echo "Final danted.conf:"
cat /etc/danted.conf

# Start health check HTTP server in background on a different port
# Use 8080 for health check, or 10000 if PORT is already used
HEALTH_PORT=8080
echo "Starting health check server on port $HEALTH_PORT..."
python3 /healthcheck.py $HEALTH_PORT > /dev/null 2>&1 &

# Start danted in foreground
echo "Starting danted..."
exec danted -f /etc/danted.conf

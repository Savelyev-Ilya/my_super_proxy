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
# On Render, PORT is usually set automatically, but we want to use 1080 for SOCKS
# So we'll check if PORT is set and different from 1080, we'll use it
# Otherwise default to 1080
if [ -n "$PORT" ] && [ "$PORT" != "1080" ]; then
  echo "WARNING: PORT is set to $PORT, but SOCKS proxy should use 1080"
  echo "Consider setting PORT=1080 in Render settings, or use the port $PORT"
  SOCKS_PORT=$PORT
else
  SOCKS_PORT=1080
fi
echo "Using SOCKS port: $SOCKS_PORT"

# Replace placeholders in config
sed -e "s/__EXTERNAL_IFACE__/$EXTERNAL_IFACE/" \
    -e "s/port = 1080/port = $SOCKS_PORT/" \
  /etc/danted.conf.template > /etc/danted.conf

echo "Final danted.conf:"
cat /etc/danted.conf

# Start health check HTTP server in background on a different port
# Use 8080 for health check
HEALTH_PORT=8080
echo "Starting health check server on port $HEALTH_PORT..."
python3 /healthcheck.py $HEALTH_PORT > /dev/null 2>&1 &

# Wait a moment for health check to start
sleep 1

# Verify danted config is valid
echo "Validating danted configuration..."
danted -f /etc/danted.conf -V 2>&1 || {
  echo "ERROR: danted configuration validation failed!"
  exit 1
}

# Check if danted process will start
echo "Starting danted on port $SOCKS_PORT..."
echo "Configuration summary:"
echo "  - SOCKS port: $SOCKS_PORT"
echo "  - External interface: $EXTERNAL_IFACE"
echo "  - User: $DANTE_USER"

# Start danted in foreground
exec danted -f /etc/danted.conf

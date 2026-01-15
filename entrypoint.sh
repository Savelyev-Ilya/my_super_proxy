#!/bin/sh
set -e

echo "Starting entrypoint"

if [ -z "$DANTE_USER" ] || [ -z "$DANTE_PASS" ]; then
  echo "ERROR: DANTE_USER or DANTE_PASS is not set"
  exit 1
fi

echo "Creating user..."
adduser --disabled-password --gecos "" "$DANTE_USER"
echo "$DANTE_USER:$DANTE_PASS" | chpasswd
id "$DANTE_USER"

echo "Detecting outbound interface..."
EXTERNAL_IFACE=$(ip route get 1.1.1.1 | awk '{print $5; exit}')

if [ -z "$EXTERNAL_IFACE" ]; then
  echo "ERROR: could not detect external interface"
  exit 1
fi

echo "Using external interface: $EXTERNAL_IFACE"

sed "s/__EXTERNAL_IFACE__/$EXTERNAL_IFACE/" \
  /etc/danted.conf.template > /etc/danted.conf

echo "Final danted.conf:"
cat /etc/danted.conf

echo "Starting danted..."
exec danted -f /etc/danted.conf -D

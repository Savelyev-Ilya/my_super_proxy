#!/bin/sh
set -e

# Создаём пользователя из env-переменных
adduser \
  --disabled-password \
  --gecos "" \
  "$DANTE_USER"

echo "$DANTE_USER:$DANTE_PASS" | chpasswd

exec danted -f /etc/danted.conf -D

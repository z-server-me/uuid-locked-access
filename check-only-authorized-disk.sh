#!/bin/bash
AUTHORIZED_UUID="e55055f6-c8a4-45a0-a0a3-d3c12ab12905"
FOUND=$(lsblk -o UUID | grep -v "$AUTHORIZED_UUID" | grep -v "^$" | wc -l)

if [ "$FOUND" -ne 0 ]; then
  echo "Disque non autorisé détecté sur PBS !" | \
  curl -s -X POST "https://api.telegram.org/bot<token>/sendMessage" \
  -d chat_id=<chat_id> -d text="$(hostname): Un disque non autorisé est branché !"
fi

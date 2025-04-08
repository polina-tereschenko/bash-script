#!/bin/bash

TOKEN=""

list=$(curl -s -H "Authorization: Bearer $TOKEN" https://grafana.url/api/search | jq -r '[.[].uid] | join(" ")')

if [ -d "dashboards" ]; then
    echo "Папка є"
    rm -f dashboards/*
    echo "Файли видалено"
else
    echo "Папки немає"
    mkdir -p dashboards
    echo "Папку створено"
fi

for uid in $list; do
    echo "Завантаження UID: $uid"
    curl -s -H "Authorization: Bearer $TOKEN" https://grafana.url/api/dashboards/uid/$uid | jq > dashboards/$uid.json
done

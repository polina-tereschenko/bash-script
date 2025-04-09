#!/bin/bash

while [[ $# -gt 0 ]]; do
    case "$1" in
    --api_token)
        api_token="$2"
        shift 2
        ;;
    --grafana_url)
        grafana_url="$2"
        shift 2
        ;;
    *)
        echo "Невідома опція: $1"
        exit 1
        ;;
    esac
done

if [[ -z "$api_token" || -z "$grafana_url" ]]; then
    echo "Помилка: необхідно передати --api_token та --grafana_url"
    exit 1
fi

echo "API Token: $api_token"
echo "Grafana URL: $grafana_url"

dashboards=$(curl -s -H "Authorization: Bearer $api_token" "$grafana_url/api/search" | jq -c '.[] | {uid: .uid, title: .title}')

if [ -d "dashboards" ]; then
    echo "Папка є"
    rm -f dashboards/*
    echo "Файли видалено"
else
    echo "Папки немає"
    mkdir -p dashboards
    echo "Папку створено"
fi

echo "$dashboards" | while read -r item; do
    uid=$(echo "$item" | jq -r '.uid')
    title=$(echo "$item" | jq -r '.title')

    safe_title=$(echo "$title" | sed 's/[^a-zA-Z0-9]/_/g' | tr 'A-Z' 'a-z')

    echo "Завантаження: $title ($uid)"
    curl -s -H "Authorization: Bearer $api_token" "$grafana_url/api/dashboards/uid/$uid" | jq >"dashboards/${safe_title}.json"
done

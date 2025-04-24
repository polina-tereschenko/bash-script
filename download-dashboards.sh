#!/bin/bash

for program in jq curl; do
    if ! command -v "$program" >/dev/null 2>&1; then
        echo "You need to install $program"
        exit 1
    fi
done

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
        echo "Unknown argument: $1"
        exit 2
        ;;
    esac
done

if [[ -z "$grafana_url" ]]; then
    echo "Error: you didn't pass argument --grafana_url"
    exit 3
fi

if ! curl --silent --header "Authorization: Bearer $api_token" --fail "$grafana_url/api/health" >/dev/null; then
    echo "Grafana is unavailable"
    exit 4
fi

response=$(curl --silent --header "Authorization: Bearer $api_token" "$grafana_url/api/search")

if echo "$response" | jq -e '.statusCode >= 400' >/dev/null; then
    echo "Error: Invalid API key"
    exit 5
fi

if [ -d "dashboards" ]; then
    echo "Folder exist"
    rm -f dashboards/*
    echo "Old files deleted"
else
    echo "The folder does not exist"
    mkdir -p dashboards
    echo "Folder created"
fi

dashboards=$(curl --silent --header "Authorization: Bearer $api_token" "$grafana_url/api/search" | jq --compact-output '.[] | {uid: .uid, title: .title}')

echo "$dashboards" | while read -r item; do
    uid=$(echo "$item" | jq --raw-output '.uid')
    title=$(echo "$item" | jq --raw-output '.title')

    safe_title=$(echo "$title" | sed 's/[^a-zA-Z0-9]/_/g' | tr 'A-Z' 'a-z')

    echo "Download: $title ($uid)"
    curl --silent --header "Authorization: Bearer $api_token" "$grafana_url/api/dashboards/uid/$uid" | jq >"dashboards/${safe_title}.json"
done

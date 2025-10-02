#!/bin/bash

set -e

CA_NAME=example-name
COMMON_NAME=example.org
COUNTRY=UA
STATE=exampleState
ORGANIZATION=example
ORGANIZATION_UNIT=example
EMAIL_ADDRESS=example@mail.org
ROOT_DOMAIN=example.org

if [[ -z "${COUNTRY:-}" ]]; then
  echo "Error: you not set parameter COUNTRY" 
  exit 2 
fi

if [[ -z "${STATE:-}" ]]; then
  echo "Error: you not set parameter STATE" 
  exit 3 
fi

if [[ -z "${ORGANIZATION:-}" ]]; then 
  echo "Error: you not set parameter ORGANIZATION"
  exit 4 
fi

if [[ -z "${COMMON_NAME:-}" ]]; then 
  echo "Error: you not set parameter COMMON_NAME" 
  exit 5 
fi

if [[ -z "${EMAIL_ADDRESS:-}" ]]; then
  echo "Error: you not set parameter EMAIL_ADDRESS" 
  exit 6
fi

if [[ -z "${ROOT_DOMAIN:-}" ]]; then
  echo "Error: you not set parameter ROOT_DOMAIN" 
  exit 7
fi

openssl genrsa -out $CA_NAME.key 4096

openssl req -new -x509 \
    -days 3650 \
    -subj "/C=$COUNTRY/ST=$STATE/L=$STATE/O=$ORGANIZATION/OU=$ORGANIZATION_UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL_ADDRESS" \
    -key $CA_NAME.key \
    -out $CA_NAME-certificate.crt

openssl req -new \
    -subj "/C=$COUNTRY/ST=$STATE/L=$STATE/O=$ORGANIZATION/OU=$ORGANIZATION_UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL_ADDRESS" \
    -key $CA_NAME.key \
    -out server.csr

echo "subjectAltName = @alt_names
[alt_names]
DNS.1 = traefik.$ROOT_DOMAIN
DNS.2 = *.$ROOT_DOMAIN" > ~/bash-script/v3ext-gen.sh

openssl x509 -req \
    -in server.csr \
    -CA $CA_NAME-certificate.crt \
    -CAkey $CA_NAME.key \
    -CAcreateserial \
    -extfile ~/bash-script/v3ext-gen.sh \
    -out $CA_NAME-server.crt \
    -days 3650 -sha256

echo "Додайте сертифікат сервера у довірені для свого веб-браузера, та системи."

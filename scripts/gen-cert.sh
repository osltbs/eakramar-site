#!/usr/bin/env bash
# Самоподписанный сертификат для ОБКАТКИ на виртуалке.
# На боевом домене используется Let's Encrypt — этот скрипт там не нужен.
# Результат в ./certs — каталог в .gitignore.

set -euo pipefail

DOMAIN="${1:-eakramar.ru}"
CERT_DIR="$(dirname "$0")/../certs"
DAYS=825

mkdir -p "$CERT_DIR"

# имена файлов ТЕ ЖЕ, что у Let's Encrypt — fullchain.pem и privkey.pem,
# чтобы nginx/default.conf работал без правок при переходе на бой
openssl req -x509 -nodes \
  -newkey rsa:2048 \
  -keyout "$CERT_DIR/privkey.pem" \
  -out    "$CERT_DIR/fullchain.pem" \
  -days   "$DAYS" \
  -subj   "/C=RU/ST=Krasnoyarsk/L=Minusinsk/O=Homelab/CN=$DOMAIN" \
  -addext "subjectAltName=DNS:$DOMAIN,DNS:www.$DOMAIN,DNS:localhost,IP:127.0.0.1"

chmod 644 "$CERT_DIR/fullchain.pem"
chmod 644 "$CERT_DIR/privkey.pem"

echo "Самоподписанный сертификат для $DOMAIN создан:"
openssl x509 -in "$CERT_DIR/fullchain.pem" -noout -subject -dates -ext subjectAltName

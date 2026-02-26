#!/usr/bin/env bash
set -euo pipefail

ENV_FILE=".mautic-api.env"

echo "=== Mautic API Configuration ==="
echo ""

if [[ -f "$ENV_FILE" ]]; then
    echo "Existing config found at $ENV_FILE"
    read -rp "Overwrite? [y/N] " overwrite
    [[ "$overwrite" =~ ^[Yy]$ ]] || { echo "Keeping existing config."; exit 0; }
fi

read -rp "Mautic URL (e.g. https://mautic.example.com): " url
url="${url%/}"

read -rp "Username (email): " user
read -rsp "Password: " pass
echo ""

echo "Testing connection..."
status=$(curl -sk -o /dev/null -w "%{http_code}" \
    -u "$user:$pass" \
    "$url/api/contacts?limit=1" 2>/dev/null || true)

if [[ "$status" == "200" ]]; then
    echo "Connection successful!"
elif [[ "$status" == "401" ]]; then
    echo "ERROR: Authentication failed (401). Check username/password."
    exit 1
elif [[ "$status" == "403" ]]; then
    echo "ERROR: API access forbidden (403). Enable API in Mautic Settings > API Settings."
    exit 1
elif [[ "$status" == "000" ]]; then
    echo "ERROR: Could not reach $url. Check the URL and network."
    exit 1
else
    echo "WARNING: Unexpected status $status. Saving config anyway."
fi

cat > "$ENV_FILE" <<EOF
MAUTIC_URL="$url"
MAUTIC_USER="$user"
MAUTIC_PASSWORD="$pass"
EOF

chmod 600 "$ENV_FILE"
echo "Config saved to $ENV_FILE"
echo ""
echo "Add to .gitignore:"
echo "  echo '.mautic-api.env' >> .gitignore"

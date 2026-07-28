#!/bin/bash
# Emit #identity events for accounts by calling updateHandle with their current handle.
# This forces the AppView to pick up the new PDS endpoint from the PLC.
#
# Usage: Set passwords below, then run: bash emit-identity.sh

PDS_URL="http://localhost:3000"

# Set your passwords here
GOV_PASSWORD=""
RABBITHOLE_PASSWORD=""
MONTREAL_PASSWORD=""

declare -A ACCOUNTS=(
  ["did:plc:tztzxg26o2rdzyceoejkupnw"]="gov.glados.computer"
  ["did:plc:jdpzxfldgzairmofrxgjheza"]="rabbithole.land"
  ["did:plc:q23vagi5ieviexdejud4nf2l"]="montreal.atproto.camp"
)

declare -A PASSWORDS=(
  ["did:plc:tztzxg26o2rdzyceoejkupnw"]="$GOV_PASSWORD"
  ["did:plc:jdpzxfldgzairmofrxgjheza"]="$RABBITHOLE_PASSWORD"
  ["did:plc:q23vagi5ieviexdejud4nf2l"]="$MONTREAL_PASSWORD"
)

for did in "${!ACCOUNTS[@]}"; do
  handle="${ACCOUNTS[$did]}"
  password="${PASSWORDS[$did]}"

  if [ -z "$password" ]; then
    echo "SKIP $handle (no password set)"
    continue
  fi

  token=$(curl -s "$PDS_URL/xrpc/com.atproto.server.createSession" \
    -H "Content-Type: application/json" \
    -d "{\"identifier\":\"$did\",\"password\":\"$password\"}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('accessJwt',''))")

  if [ -z "$token" ]; then
    echo "FAIL $handle (login failed)"
    continue
  fi

  result=$(curl -s -X POST "$PDS_URL/xrpc/com.atproto.identity.updateHandle" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "{\"handle\":\"$handle\"}")

  if [ -z "$result" ]; then
    echo "OK   $handle"
  else
    echo "FAIL $handle: $result"
  fi
done

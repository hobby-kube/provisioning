#!/bin/sh
set -e

private_key=$(wg genkey)
public_key=$(echo $private_key | wg pubkey)

jq -n --arg private_key "$private_key" \
  --arg public_key "$public_key" \
  '{"private_key":$private_key,"public_key":$public_key}'

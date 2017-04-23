#!/bin/sh
set -e

random_string () {
  cat /dev/urandom | LC_ALL=C LC_CTYPE=C tr -dc 'a-f0-9' | fold -w $1 | head -n 1
}

token=$(random_string 6).$(random_string 16)

jq -n --arg token $token '{"token": $token}'

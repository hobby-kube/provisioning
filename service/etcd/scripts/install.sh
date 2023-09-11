#!/bin/sh
set -eu

[ $# = 1 ] || { >&2 echo "Usage: ${0} ETCD_VERSION"; exit 1; }

version="${1}"
if ! echo "${version}" | grep -qE '^v[0-9]'; then
  >&2 printf "ERROR: Must provide valid etcd version, got \`%s\`\n" "${version}"
  exit 1
fi

arch="$(arch | sed 's/x86_64/amd64/; s/aarch64/arm64/')"

rm -f "/opt/etcd-${version}-linux-${arch}.tar.gz"
rm -rf /opt/etcd && mkdir -p /opt/etcd

(
  set -x
  curl --fail-with-body -L "https://storage.googleapis.com/etcd/${version}/etcd-${version}-linux-${arch}.tar.gz" \
    -o "/opt/etcd-${version}-linux-${arch}.tar.gz"
  tar xzvf "/opt/etcd-${version}-linux-${arch}.tar.gz" -C /opt/etcd --strip-components=1
  rm "/opt/etcd-${version}-linux-${arch}.tar.gz"
)

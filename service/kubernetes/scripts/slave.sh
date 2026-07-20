#!/bin/sh
set -eu

echo "Waiting for API server"
until nc -z "${master_ip}" 6443; do
  echo "Waiting for API server ${master_ip}:6443 to respond"
  sleep 5
done

echo "kubeadm join"
kubeadm join --config /tmp/worker-kubeadm-configuration.yml

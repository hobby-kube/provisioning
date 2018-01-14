#!/bin/sh
set -e

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial-unstable main
EOF
apt-get update
apt-get install -y docker.io
apt-get install -y kubelet kubeadm kubectl kubernetes-cni

# See: https://github.com/hobby-kube/guide/issues/11
ip route add 10.96.0.0/16 dev ${vpn_interface} src ${vpn_ip}
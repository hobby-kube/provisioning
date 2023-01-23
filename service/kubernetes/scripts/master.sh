#!/bin/sh
set -eu

echo "kubeadm init"
kubeadm init --config /tmp/master-configuration.yml \
  --ignore-preflight-errors=Swap,NumCPU

kubeadm token create "${token}"

[ -d $HOME/.kube ] || mkdir -p $HOME/.kube
ln -s /etc/kubernetes/admin.conf $HOME/.kube/config

echo "Waiting for API server"
until nc -z localhost 6443; do
  echo "Waiting for API server to respond"
  sleep 5
done

echo "Install CNI"
kubectl apply -f "https://github.com/weaveworks/weave/releases/download/${weave_net_version}/weave-daemonset-k8s.yaml"

echo "Add cluster role binding"
# See: https://kubernetes.io/docs/admin/authorization/rbac/
kubectl create clusterrolebinding permissive-binding \
  --clusterrole=cluster-admin \
  --user=admin \
  --user=kubelet \
  --group=system:serviceaccounts

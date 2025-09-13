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
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH="$(arch | sed 's/x86_64/amd64/; s/aarch64/arm64/')"
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/$${CILIUM_CLI_VERSION}/cilium-linux-$${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-$${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-$${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-$${CLI_ARCH}.tar.gz*

cilium install --version ${cilium_version} --set ipam.mode=cluster-pool --set ipam.operator.clusterPoolIPv4PodCIDRList=${overlay_cidr} %{ for arg in cilium_install_extra_args ~} ${arg} %{ endfor ~}
cilium status --wait

echo "Add cluster role binding"
# See: https://kubernetes.io/docs/admin/authorization/rbac/
kubectl create clusterrolebinding permissive-binding \
  --clusterrole=cluster-admin \
  --user=admin \
  --user=kubelet \
  --group=system:serviceaccounts

#!/bin/sh
set -e

# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management (yes, `xenial` is correct even for newer Ubuntu versions)
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmour -o /etc/apt/keyrings/docker.gpg
echo "deb [signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt-get update


# Use `DEBIAN_FRONTEND=noninteractive` to avoid starting containerd already with Ubuntu's minimal config.
#
# Kubernetes 1.26+ requires at least containerd v1.6.
DEBIAN_FRONTEND=noninteractive apt-get install -y containerd.io=1.6.22-1

containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable containerd
systemctl restart containerd

# Pin Kubernetes major version since there are breaking changes between releases.
# For example, Kubernetes 1.26 requires a newer containerd (https://kubernetes.io/blog/2022/11/18/upcoming-changes-in-kubernetes-1-26/#cri-api-removal).
apt-get install -y kubelet=1.28.0-00 kubeadm=1.28.1-00 kubectl=1.28.1-00 # kubernetes-cni package comes as dependency of the others
apt-mark hold kubelet kubeadm kubectl kubernetes-cni

echo "Installation of packages done"

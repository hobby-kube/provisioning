#!/bin/sh
set -e

# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' > /etc/apt/sources.list.d/kubernetes.list

# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --batch --yes --dearmour -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" > /etc/apt/sources.list.d/docker.list

apt-get update


# Use `DEBIAN_FRONTEND=noninteractive` to avoid starting containerd already with Ubuntu's minimal config.
#
# Kubernetes 1.26+ requires at least containerd v1.6.
DEBIAN_FRONTEND=noninteractive apt-get install -y containerd.io=1.7.19-1

containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml # https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd
systemctl enable containerd
systemctl restart containerd

# Pin Kubernetes major version since there are breaking changes between releases.
# For example, Kubernetes 1.26 requires a newer containerd (https://kubernetes.io/blog/2022/11/18/upcoming-changes-in-kubernetes-1-26/#cri-api-removal).
apt-get install -y kubelet=1.30.3-1.1 kubeadm=1.30.3-1.1 kubectl=1.30.3-1.1 # kubernetes-cni package comes as dependency of the others
apt-mark hold kubelet kubeadm kubectl kubernetes-cni

echo "Installation of packages done"

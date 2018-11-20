#!/bin/sh
set -e

# Install kernel headers with apt
if apt-cache show -q linux-headers-$(uname -r) > /dev/null 2>&1 /dev/null; then
  echo "Installing Linux headers using apt"
  apt-get -yq install linux-headers-$(uname -r)
  exit $?
fi

# See: https://github.com/scaleway/kernel-tools
echo "Installing Linux headers from kernel.org"
# Determine versions
arch="$(uname -m)"
release="$(uname -r)"
upstream="${release%%-*}"
local="${release#*-}"

# Get kernel sources
mkdir -p /usr/src
wget --quiet -O "/usr/src/linux-${upstream}.tar.xz" "https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${upstream}.tar.xz"
tar xf "/usr/src/linux-${upstream}.tar.xz" -C /usr/src/
ln -fns "/usr/src/linux-${upstream}" /usr/src/linux
ln -fns "/usr/src/linux-${upstream}" "/lib/modules/${release}/build"

# Prepare kernel
zcat /proc/config.gz > /usr/src/linux/.config
printf 'CONFIG_LOCALVERSION="%s"\nCONFIG_CROSS_COMPILE=""\n' "${local:+-$local}" >> /usr/src/linux/.config
wget --quiet -O /usr/src/linux/Module.symvers "http://mirror.scaleway.com/kernel/${arch}/${release}/Module.symvers"
apt-get install -y libssl-dev # adapt to your package manager
make -C /usr/src/linux prepare modules_prepare

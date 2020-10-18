# libvirt Provisioner

[Terraform provider for libvirt](https://github.com/dmacvicar/terraform-provider-libvirt) is a non-official Terraform provider to provision KVM/QEMU based virtual machines.
This module integrates the libvirt provider with hobby-kube.

## Prerequisites

First of all, a working KVM / QEMU host is needed.
The module works both on the same host as well as on a machine with `qemu+ssh`-access to a host machine.
Some installations have to be made on the machine that is used for Terraform provisioning:

* terraform-provider-libvirt
* mkisofs

### Linux

[Download a suitable terraform-provider-libvirt release](https://github.com/dmacvicar/terraform-provider-libvirt/releases) and extract the binary.
Once the binary is extracted, it can be placed in the user's Terraform plugins cache:

```
export TERRAFORM_LIBVIRT_VERSION="0.6.2"
mkdir -p ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/$TERRAFORM_LIBVIRT_VERSION/linux_amd64
cp terraform-provider-libvirt ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/$TERRAFORM_LIBVIRT_VERSION/linux_amd64
```

More information on how to install the provider for Terraform >= 0.13 can be found [here](https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/docs/migration-13.md).

`mkisofs` is also needed.
On Ubuntu it can be installed with

```
sudo apt install genisoimage
```

### MacOS

There is no pre-compiled binary for terraform-provider-libvirt for MacOS.
Instead, it can be [built from source](https://github.com/dmacvicar/terraform-provider-libvirt#building-from-source).

Similar to Linux, the resulting binary needs to be placed in the user's terraform plugin cache directory:

```
export TERRAFORM_LIBVIRT_VERSION="0.6.2"
mkdir -p ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/$TERRAFORM_LIBVIRT_VERSION/darwin_amd64
cp terraform-provider-libvirt ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/$TERRAFORM_LIBVIRT_VERSION/darwin_amd64
```

`mkisofs` is also needed.
It comes with `cdrtools`, which can be installed with Homebrew:

```
brew install cdrtools
```

# libvirt Provisioner

[Terraform provider for libvirt](https://github.com/dmacvicar/terraform-provider-libvirt) is a non-official Terraform provider to provision KVM/QEMU based virtual machines.
This module integrates the libvirt provider with hobby-kube.

## Prerequisites

First of all, a working KVM / QEMU host with bridged networking is needed.
The module works both when provisioned from the virtualization host as well as on a machine with `qemu+ssh`-access to a host machine.
Some installations have to be made **on the machine that is used for Terraform provisioning**:

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

## Usage and Configuration

Uncomment the libvirt-provider module in the top-level `main.tf` file.
Configure your desired setup in `terraform.tfvars`.

See provided `terraform.tfvars.example` for possible options and explanations.

### Network Setup

For now, only bridged networking is supported.
Bridge `br0` must be provisioned on the virtualization host.

Nodes will be provisioned with static IP Addresses within the given briged network.
Given your bridged network is `192.168.100.0/24`, a minimim viable configuration with three hosts and IP addresses counted from `192.168.100.120` looks like this:

```
# Count of nodes to provide (must be provided)
node_count                       = 3

# Range of IPs in the bridged host network to use for provisioning
# (must be provided)
libvirt_public_iprange           = "192.168.100.0/24"

# Offset in public ip range to start with when providing node IPs (default: 1)
libvirt_public_iprange_offset    = 120

# The gateway for the node to use
# (must be provided)
libvirt_public_gateway           = "192.168.100.1"

# The nameserver for the node to use
# (must be provided)
libvirt_public_nameserver        = "192.168.100.1"
```

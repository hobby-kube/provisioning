# Kubernetes cluster setup automation

> This is part of the Hobby Kube project. Functionality of the modules is described in the [guide](https://github.com/hobby-kube/guide).

Deploy a secure Kubernetes cluster on [Hetzner Cloud](https://www.hetzner.com/cloud), [Scaleway](https://www.scaleway.com/), [DigitalOcean](https://www.digitalocean.com/) or [Packet](https://www.packet.com/) using [Terraform](https://www.terraform.io/).

## Setup

### Requirements

The following packages are required to be installed locally:

```sh
brew install terraform kubectl jq wireguard-tools
```

Modules are using ssh-agent for remote operations. Add your SSH key with `ssh-add -K` if Terraform repeatedly fails to connect to remote hosts.

### Configuration

**Important:** Modify only [main.tf](main.tf) in project root, comment or uncomment sections as needed. All variables in [variables.tf](variables.tf) can be set
either directly or from environment variable.

Export the following environment variables depending on the modules you're using:

#### Set number of hosts (nodes)

```sh
export TF_VAR_node_count=3
```

#### Set number of etcd members

The first N nodes will be part of the etcd cluster.
3 or 5 are good values, see [here](https://coreos.com/etcd/docs/latest/faq.html#system-requirements).

```sh
export TF_VAR_etcd_node_count=3
```

#### Using Hetzner Cloud as provider

```sh
export TF_VAR_hcloud_token=<token>
export TF_VAR_hcloud_ssh_keys=<keys>
export TF_VAR_hcloud_ssh_keys='["<description-key1>", "<description-key2>"]'
# Defaults:
# export TF_VAR_hcloud_location="nbg1"
# export TF_VAR_hcloud_type="cx11"
# export TF_VAR_hcloud_image="ubuntu-20.04"
```

SSH keys are referenced by their description. Visit the Hetzner Cloud console at
`https://console.hetzner.cloud/projects/<project-id>/access/sshkeys`

#### Using Scaleway as provider

```sh
export TF_VAR_scaleway_organization_id=<organization_id>
export TF_VAR_scaleway_access_key=<access_key> # can be omitted for now
export TF_VAR_scaleway_secret_key=<secret_key>
# Defaults:
# export TF_VAR_scaleway_zone="nl-ams-1"
# export TF_VAR_scaleway_type="DEV1-S"
# export TF_VAR_scaleway_image="Ubuntu 20.04 Focal Fossa"

```

#### Using DigitalOcean as provider

```sh
export TF_VAR_digitalocean_token=<token>
export TF_VAR_digitalocean_ssh_keys=<keys>
export TF_VAR_digitalocean_ssh_keys='["<id-key1>", "<id-key2>"]'
# Defaults:
# export TF_VAR_digitalocean_region="fra1"
# export TF_VAR_digitalocean_size="1gb"
# export TF_VAR_digitalocean_image="ubuntu-20-04-x64"
```

You can get SSH key IDs using [this API](https://developers.digitalocean.com/documentation/v2/#list-all-keys).

#### Using Packet as provider

```sh
export TF_VAR_packet_auth_token=<token>
export TF_VAR_packet_project_id=<uuid>
# Defaults:
# export TF_VAR_packet_facility="sjc1"
# export TF_VAR_packet_plan="c1.small.x86"
# export TF_VAR_packet_operating_system="ubuntu_20_04"
```

#### Using vSphere as provider

```sh
export TF_VAR_vsphere_server=<FQDN or IP of vCenter Server>
export TF_VAR_vsphere_datacenter=<vSphere Datacenter Name>
export TF_VAR_vsphere_cluster=<vSphere Cluster Name>
export TF_VAR_vsphere_network=<vSphere Network Name>
export TF_VAR_vsphere_datastore=<vSphere Datastore Name>
export TF_VAR_vsphere_vm_template=<vSphere VM Template Name>
export TF_VAR_vsphere_user=<vSphere Admin Username>
export TF_VAR_vsphere_password=<vSphere Admin Password>
# Defaults:
# export TF_VAR_vsphere_vm_linked_clone=false
# export TF_VAR_vsphere_vm_num_cpus="2"
# export TF_VAR_vsphere_vm_memory="2048"
```

Template VM needs to pre-configured so that root can login using SSH key.

#### Using UpCloud as provider

```sh
export TF_VAR_upcloud_username=<UpCloud API account username>
export TF_VAR_upcloud_password=<UpCloud API account password>
export TF_VAR_upcloud_ssh_keys='["<PUBLIC KEY HERE>"]'
# Defaults:
# export TF_VAR_upcloud_zone="de-fra1"
# export TF_VAR_upcloud_plan="1xCPU-2GB"
# export TF_VAR_upcloud_disk_template="Ubuntu Server 20.04 LTS (Focal Fossa)"
```

You will need API credentials to use the UpCloud terraform provider, see https://upcloud.com/community/tutorials/getting-started-upcloud-api/ for more info.

#### Using Cloudflare for DNS entries

```sh
export TF_VAR_domain=<domain> # e.g. example.org
export TF_VAR_cloudflare_email=<email>
export TF_VAR_cloudflare_api_token=<token>
```

#### Using Amazon Route 53 for DNS entries

```sh
export TF_VAR_domain=<domain> # e.g. example.org shall be already added to hosted zones.
export TF_VAR_aws_access_key=<ACCESS_KEY>
export TF_VAR_aws_secret_key=<SECRET_KEY>
export TF_VAR_aws_region=<region> # e.g. eu-west-1
```

#### Install additional APT packages

Each provider takes an optional variable to install further packages during provisioning:

```
module "provider" {
  # ...
  apt_packages = ["ceph-common", "nfs-common"]
}
```

#### Add more firewall rules

Security/ufw takes an optional variable to add custom firewall rules during provisioning:

```
module "firewall" {
  # ...
  additional_rules = ["allow 1194/udp", "allow ftp"]
}
```

### Execute

From the root of this project...

```sh
# fetch the required modules
$ terraform init

# see what `terraform apply` will do
$ terraform plan

# execute it
$ terraform apply
```

## Using modules independently

Modules in this repository can be used independently:

```hcl
module "kubernetes" {
  source = "github.com/hobby-kube/provisioning/service/kubernetes"
}
```

After adding this to your plan, run `terraform get` to fetch the module.

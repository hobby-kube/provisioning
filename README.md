# Kubernetes cluster setup automation

> This is part of the Hobby Kube project. Functionality of the modules is described in the [guide](https://github.com/hobby-kube/guide).

Deploy a secure Kubernetes cluster on [Hetzner Cloud](https://www.hetzner.com/cloud), [Scaleway](https://www.scaleway.com/) or [DigitalOcean](https://www.digitalocean.com/) using [Terraform](https://www.terraform.io/).


## Setup


### Requirements

The following packages are required to be installed locally:

```sh
brew install terraform kubectl jq wireguard-tools
```

Modules are using ssh-agent for remote operations. Add your SSH key with `ssh-add -K` if Terraform repeatedly fails to connect to remote hosts.


### Configuration

**Important:** Modify only `/main.tf` in project root, comment or uncomment sections as needed. All variables in `/variables.tf` can be set
either directly or by exporting evironment variables following the form `TF_VAR_<var_name>` (see `/variables.tf` for examples).

Export the following environment variables depending on the modules you're using.


#### Set Number of Machines (Nodes)

```sh
export TF_VAR_node_count=5 # Defaults to 3
```


#### Using Hetzner Cloud as provider

```sh
export TF_VAR_hcloud_token=<token>
export TF_VAR_hcloud_ssh_keys=<keys>
# e.g.
# export TF_VAR_hcloud_ssh_keys='["~/.ssh/id_rsa1.pub", "~/.ssh/id_rsa2.pub"]'
```


#### Using Scaleway as provider

```sh
export TF_VAR_scaleway_organization=<access_key>
export TF_VAR_scaleway_token=<token>
```


#### Using DigitalOcean as provider

```sh
export TF_VAR_digitalocean_token=<token>
export TF_VAR_digitalocean_ssh_keys=<keys>
# e.g.
# export TF_VAR_digitalocean_ssh_keys='["~/.ssh/id_rsa1.pub", "~/.ssh/id_rsa2.pub"]'
```


#### Using Cloudflare for DNS entries

```sh
export TF_VAR_domain=<domain> # e.g. example.org
export TF_VAR_cloudflare_email=<email>
export TF_VAR_cloudflare_token=<token>
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

```
module "kubernetes" {
  source  = "github.com/hobby-kube/provisioning/service/kubernetes"
}
```

After adding this to your plan, run `terraform get` to fetch the module.

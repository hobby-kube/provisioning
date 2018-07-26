
/* GENERAL */

# number of machines to provision
# export TF_VAR_node_count=5
variable "node_count" {
  default = 3
}

variable "domain" {
  default = "example.com"
}

variable "hostname_format" {
  default = "kube%d"
}


/* HCLOUD */

# export TF_VAR_hcloud_token=$(cat /my/secret/tokens/hcloud_token.txt)
variable "hcloud_token" {
  default = ""
}

# export TF_VAR_hcloud_ssh_keys='["$(cat ~/.ssh/id_rsa_key1.pub)", "$(cat ~/.ssh/id_rsa_key2.pub)"]'
variable "hcloud_ssh_keys" {
  default = []
}

variable "hcloud_location" {
  default = "nbg1"
}

variable "hcloud_type" {
  default = "cx11"
}


/* SCALEWAY */

variable "scaleway_organization" {
  default = ""
}

# export TF_VAR_scaleway_token=$(cat /my/secret/tokens/scaleway_token.txt)
variable "scaleway_token" {
  default = ""
}

variable "scaleway_region" {
  default = "ams1"
}


/* DIGITALOCEAN */

# export TF_VAR_digitalocean_token=$(cat /my/secret/tokens/digitalocean_token.txt)
variable "digitalocean_token" {
  default = ""
}

# export TF_VAR_digitalocean_ssh_keys='["$(cat ~/.ssh/id_rsa_key1.pub)", "$(cat ~/.ssh/id_rsa_key2.pub)"]'
variable "digitalocean_ssh_keys" {
  default = []
}

variable "digitalocean_region" {
  default = "fra1"
}


/* AWS DNS */

variable "aws_access_key" {
  default = ""
}

variable "aws_secret_key" {
  default = ""
}

variable "aws_region" {
  default = "eu-west-1"
}


/* CLOUDFLARE DNS */

variable "cloudflare_email" {
  default = ""
}

# export TF_VAR_cloudflare_token=$(cat /my/secret/tokens/cloudflare_token.txt)
variable "cloudflare_token" {
  default = ""
}


/* GOOGLE DNS */

variable "google_project" {
  default = ""
}

variable "google_region" {
  default = ""
}

variable "google_managed_zone" {
  default = ""
}

variable "google_credentials_file" {
  default = ""
}

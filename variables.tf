/* general */
variable "hosts" {
  default = 3
}

variable "domain" {
  default = "example.com"
}

variable "hostname_format" {
  default = "kube%d"
}

variable "apt_packages" {
  default = "nfs-common ceph-common git zsh"
}

/* scaleway */
variable "scaleway_organization" {
  default = ""
}

variable "scaleway_token" {
  default = ""
}

variable "scaleway_region" {
  default = "ams1"
}

/* Gandi DNS */
variable "gandi_api_key" {
  default = ""
}

/* digitalocean */
variable "digitalocean_token" {
  default = ""
}

variable "digitalocean_ssh_keys" {
  default = []
}

variable "digitalocean_region" {
  default = "nyc1"
}

/* aws */
variable "aws_access_key" {
  default = ""
}

variable "aws_secret_key" {
  default = ""
}

variable "aws_region" {
  default = "eu-west-1"
}

/* cloudflare */
variable "cloudflare_email" {
  default = ""
}

variable "cloudflare_token" {
  default = ""
}

/* google dns */
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

/* Oh My ZSH */
variable "zsh_plugins" {
  default = ["kops", "kubectl"]
}

variable "zsh_theme" {
  default = "ys"
}

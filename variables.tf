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

/* hcloud */
variable "hcloud_token" {
  default = ""
}

variable "hcloud_ssh_keys" {
  default = []
}

variable "hcloud_location" {
  default = "nbg1"
}

variable "hcloud_type" {
  default = "cx11"
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

/* digitalocean */
variable "digitalocean_token" {
  default = ""
}

variable "digitalocean_ssh_keys" {
  default = []
}

variable "digitalocean_region" {
  default = "fra1"
}

/* aws dns */
variable "aws_access_key" {
  default = ""
}

variable "aws_secret_key" {
  default = ""
}

variable "aws_region" {
  default = "eu-west-1"
}

/* cloudflare dns */
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

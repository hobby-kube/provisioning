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
  default = "nyc1"
}

/* dns */
variable "cloudflare_email" {
  default = ""
}

variable "cloudflare_token" {
  default = ""
}

variable "digitalocean_token" {
  default = ""
}

variable "digitalocean_ssh_keys" {
  default = []
}

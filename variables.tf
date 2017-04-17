variable "hosts" {
  default = 3
}

variable "domain" {
  default = "example.com"
}

variable "hostname_format" {
  default = "kube%d"
}

variable "scaleway_organization" {
  default = ""
}

variable "scaleway_token" {
  default = ""
}

variable "scaleway_region" {
  default = "ams1"
}

variable "cloudflare_email" {
  default = ""
}

variable "cloudflare_token" {
  default = ""
}

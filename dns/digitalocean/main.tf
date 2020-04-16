variable "node_count" {}

variable "token" {}

variable "domain" {}

variable "hostnames" {
  type = list
}

variable "public_ips" {
  type = list
}

provider "digitalocean" {
  token = var.token
}

resource "digitalocean_record" "hosts" {
  count = var.node_count

  domain = var.domain
  name   = element(var.hostnames, count.index)
  value  = element(var.public_ips, count.index)
  type   = "A"
  ttl    = 300
}

resource "digitalocean_record" "domain" {
  domain = var.domain
  name   = "@"
  value  = element(var.public_ips, 0)
  type   = "A"
  ttl    = 300
}

resource "digitalocean_record" "wildcard" {
  depends_on = ["digitalocean_record.domain"]

  domain = var.domain
  name   = "*.${var.domain}."
  value  = "@"
  type   = "CNAME"
  ttl    = 300
}

output "domains" {
  value = "${digitalocean_record.hosts.*.fqdn}"
}

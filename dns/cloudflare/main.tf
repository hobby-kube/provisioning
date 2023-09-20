locals {
  zone_id   = data.cloudflare_zone.domain_zone.id
  zone_name = regex("[a-z]*.[a-z]*$", var.domain)
}

variable "node_count" {}

variable "api_token" {}

variable "domain" {}

variable "hostnames" {
  type = list(any)
}

variable "public_ips" {
  type = list(any)
}

provider "cloudflare" {
  api_token = var.api_token
}

data "cloudflare_zone" "domain_zone" {
  name = local.zone_name
}

resource "cloudflare_record" "hosts" {
  count = var.node_count

  zone_id = local.zone_id
  name    = "${var.hostnames[count.index]}.${var.domain}"
  value   = var.public_ips[count.index]
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "domain" {
  zone_id = local.zone_id
  name    = var.domain
  value   = element(var.public_ips, 0)
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "wildcard" {
  depends_on = [cloudflare_record.domain]

  zone_id = local.zone_id
  name    = "*.${var.domain}"
  value   = var.domain
  type    = "CNAME"
  proxied = false
}

output "domains" {
  value = cloudflare_record.hosts.*.hostname
}

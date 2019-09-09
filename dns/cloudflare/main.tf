variable "node_count" {}

variable "email" {}

variable "token" {}

variable "domain" {}

variable "hostnames" {
  type = "list"
}

variable "public_ips" {
  type = "list"
}

provider "cloudflare" {
  email = "${var.email}"
  token = "${var.token}"
}

resource "cloudflare_record" "hosts" {
  node_count = "${var.node_count}"

  domain  = "${var.domain}"
  name    = "${element(var.hostnames, node_count.index)}"
  value   = "${element(var.public_ips, node_count.index)}"
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "domain" {
  domain  = "${var.domain}"
  name    = "${var.domain}"
  value   = "${element(var.public_ips, 0)}"
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "wildcard" {
  depends_on = ["cloudflare_record.domain"]

  domain  = "${var.domain}"
  name    = "*"
  value   = "${var.domain}"
  type    = "CNAME"
  proxied = false
}

output "domains" {
  value = ["${cloudflare_record.hosts.*.hostname}"]
}

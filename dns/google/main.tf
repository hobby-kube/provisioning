variable "count" {}

variable "project" {}

variable "region" {}

variable "creds_file" {}

variable "managed_zone" {}

variable "domain" {}

variable "hostnames" {
  type = "list"
}

variable "public_ips" {
  type = "list"
}

provider "google" {
  credentials = "${file(var.creds_file)}"
  project     = "${var.project}"
  region      = "${var.region}"
}

resource "google_dns_record_set" "hosts" {
  count = "${var.count}"

  name         = "${element(var.hostnames, count.index)}.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = "${var.managed_zone}"
  rrdatas      = ["${element(var.public_ips, count.index)}"]
}

resource "google_dns_record_set" "domain" {
  name         = "${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = "${var.managed_zone}"
  rrdatas      = ["${element(var.public_ips, 0)}"]
}

resource "google_dns_record_set" "wildcard" {
  depends_on = ["google_dns_record_set.domain"]

  name         = "*.${var.domain}."
  type         = "CNAME"
  ttl          = 300
  managed_zone = "${var.managed_zone}"
  rrdatas      = ["${var.domain}."]
}

output "domains" {
  value = ["${google_dns_record_set.hosts.*.name}"]
}

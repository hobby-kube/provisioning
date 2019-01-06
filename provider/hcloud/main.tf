locals {
  project_name = "demo"
}

variable "token" {
  type        = "string"
  description = "Should match HCLOUD_TOKEN"
}

variable "hosts" {
  default = 0
}

variable "hostname_prefix" {
  type        = "string"
  description = "What hostname prefix to use. Default: demo"
  default     = "demo"
}

variable "location" {
  type        = "string"
  description = "Help: `hcloud location list`"
}

variable "type" {
  type        = "string"
  description = "Help: `hcloud server-type list`"
}

variable "image" {
  type        = "string"
  description = "Help: `hcloud image list`"
}

variable "apt_packages" {
  type    = "list"
  default = []
}

variable "labels" {
  type    = "map"
  default = {}
}

provider "hcloud" {
  token = "${var.token}"
}

resource "hcloud_ssh_key" "default" {
  name       = "${local.project_name}"
  labels     = "${merge(var.labels, map("created_by", "terraform"))}"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "hcloud_server" "host" {
  name        = "${format("%s-%03d", var.hostname_prefix, count.index + 1)}"
  location    = "${var.location}"
  image       = "${var.image}"
  server_type = "${var.type}"
  ssh_keys    = ["${hcloud_ssh_key.default.id}"]
  labels      = "${merge(var.labels, map("created_by", "terraform"))}"

  count = "${var.hosts}"

  provisioner "remote-exec" {
    inline = [
      "while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 1; done",
      "apt-get update",
      "apt-get install -yq ufw ${join(" ", var.apt_packages)}",
    ]
  }
}

output "hostnames" {
  value = ["${hcloud_server.host.*.name}"]
}

output "public_ips" {
  value = ["${hcloud_server.host.*.ipv4_address}"]
}

output "private_ips" {
  value = ["${hcloud_server.host.*.ipv4_address}"]
}

output "private_network_interface" {
  value = "eth0"
}

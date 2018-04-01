variable "token" {}

variable "hosts" {
  default = 0
}

variable "hostname_format" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "type" {
  type = "string"
}

variable "image" {
  type    = "string"
  default = "ubuntu-16.04"
}

variable "ssh_keys" {
  type = "list"
}

provider "hcloud" {
  token = "${var.token}"
}

variable "apt_packages" {
  type    = "list"
  default = []
}

resource "hcloud_server" "host" {
  name        = "${format(var.hostname_format, count.index + 1)}"
  location    = "${var.location}"
  image       = "${var.image}"
  server_type = "${var.type}"
  ssh_keys    = ["${var.ssh_keys}"]

  count = "${var.hosts}"

  provisioner "remote-exec" {
    inline = [
      "while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do sleep 1; done",
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

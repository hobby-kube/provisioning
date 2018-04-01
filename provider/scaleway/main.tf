variable "organization" {}

variable "token" {}

variable "hosts" {
  default = 0
}

variable "hostname_format" {
  type = "string"
}

variable "region" {
  type    = "string"
  default = "ams1"
}

variable "type" {
  type    = "string"
  default = "VC1S"
}

variable "image" {
  type    = "string"
  default = "Ubuntu Xenial"
}

variable "apt_packages" {
  type    = "list"
  default = []
}

# variable "storage_size" {
#   default = 50
# }

provider "scaleway" {
  organization = "${var.organization}"
  token        = "${var.token}"
  region       = "${var.region}"
}

resource "scaleway_server" "host" {
  name                = "${format(var.hostname_format, count.index + 1)}"
  type                = "${var.type}"
  image               = "${data.scaleway_image.image.id}"
  bootscript          = "${data.scaleway_bootscript.bootscript.id}"
  dynamic_ip_required = true

  count = "${var.hosts}"

  # volume = {
  #   size_in_gb = "${var.storage_size}"
  #   type       = "l_ssd"
  # }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -yq apt-transport-https ufw ${join(" ", var.apt_packages)}",
    ]
  }
}

data "scaleway_image" "image" {
  architecture = "x86_64"
  name         = "${var.image}"
}

data "scaleway_bootscript" "bootscript" {
  architecture = "x86_64"
  name_filter  = "4.10.8 std #1"
}

output "hostnames" {
  value = ["${scaleway_server.host.*.name}"]
}

output "public_ips" {
  value = ["${scaleway_server.host.*.public_ip}"]
}

output "private_ips" {
  value = ["${scaleway_server.host.*.private_ip}"]
}

output "private_network_interface" {
  value = "eth0"
}

variable "organization_id" {}

variable "access_key" {}

variable "secret_key" {}

variable "hosts" {
  default = 0
}

variable "hostname_format" {
  type = string
}

variable "zone" {
  type = string
}

variable "type" {
  type = string
}

variable "image" {
  type = string
}

variable "apt_packages" {
  type    = list(any)
  default = []
}

provider "scaleway" {
  organization_id = var.organization_id
  access_key      = var.access_key
  secret_key      = var.secret_key
  zone            = var.zone
  version         = ">= 1.14"
}

resource "scaleway_instance_server" "host" {
  name              = format(var.hostname_format, count.index + 1)
  type              = var.type
  image             = data.scaleway_instance_image.image.id
  enable_dynamic_ip = true

  count = var.hosts

  connection {
    user    = "root"
    type    = "ssh"
    timeout = "2m"
    host    = self.public_ip
  }


  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -yq apt-transport-https ufw ${join(" ", var.apt_packages)}",
      # fix a problem with later wireguard installation
      "DEBIAN_FRONTEND=noninteractive apt-get install -yq -o Dpkg::Options::=--force-confnew sudo",
    ]
  }
}

data "scaleway_instance_image" "image" {
  architecture = "x86_64"
  name         = var.image
}

output "hostnames" {
  value = scaleway_instance_server.host.*.name
}

output "public_ips" {
  value = scaleway_instance_server.host.*.public_ip
}

output "private_ips" {
  value = scaleway_instance_server.host.*.private_ip
}

output "private_network_interface" {
  value = "ens2"
}

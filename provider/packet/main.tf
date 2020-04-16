variable "auth_token" {}

variable "hosts" {
  default = 3
}

variable "project_id" {
  default = ""
}

variable "facility" {
  default = ""
}

variable "operating_system" {
  default = ""
}

variable "billing_cycle" {
  default = "hourly"
}

variable "plan" {
  type = string
}

variable "apt_packages" {
  type    = list
  default = []
}

variable "user_data" { default = "" }

variable "hostname_format" {
  default = ""
}

provider "packet" {
  auth_token = var.auth_token
}

resource "packet_device" "host" {
  count            = var.hosts
  hostname         = format(var.hostname_format, count.index + 1)
  plan             = var.plan
  facilities       = var.facility
  operating_system = var.operating_system
  billing_cycle    = var.billing_cycle
  project_id       = var.project_id
  user_data        = var.user_data

  connection {
    user    = "root"
    type    = "ssh"
    timeout = "2m"
    host    = self.access_public_ipv4
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

output "public_ips" {
  value = "${packet_device.host.*.access_public_ipv4}"
}

output "hostnames" {
  value = "${packet_device.host.*.hostname}"
}

output "private_ips" {
  value = "${packet_device.host.*.access_private_ipv4}"
}

output "private_network_interface" {
  value = "bond0"
}

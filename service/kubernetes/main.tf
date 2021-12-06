variable "node_count" {}

variable "connections" {
  type = list
}

variable "vpn_ips" {
  type = list
}

variable "vpn_interface" {
  type = string
}

variable "etcd_endpoints" {
  type = list
}

variable "overlay_interface" {
  default = "weave"
}

variable "overlay_cidr" {
  default = "10.96.0.0/16"
}

resource "random_string" "token1" {
  length  = 6
  upper   = false
  special = false
}

resource "random_string" "token2" {
  length  = 16
  upper   = false
  special = false
}

locals {
  cluster_token = "${random_string.token1.result}.${random_string.token2.result}"
}

resource "null_resource" "kubernetes" {
  count = var.node_count

  connection {
    host  = element(var.connections, count.index)
    user  = "root"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get install -qy jq",
      "modprobe br_netfilter && echo br_netfilter >> /etc/modules",
    ]
  }

  provisioner "remote-exec" {
    inline = ["[ -d /etc/docker ] || mkdir -p /etc/docker"]
  }

  provisioner "file" {
    content     = file("${path.module}/templates/daemon.json")
    destination = "/etc/docker/daemon.json"
  }

  provisioner "file" {
    content     = data.template_file.master-configuration.rendered
    destination = "/tmp/master-configuration.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "${element(data.template_file.install.*.rendered, count.index)}"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "${count.index == 0 ? data.template_file.master.rendered : data.template_file.slave.rendered}"
    ]
  }
}

data "template_file" "master-configuration" {
  template = file("${path.module}/templates/master-configuration.yml")

  vars = {
    api_advertise_addresses = element(var.vpn_ips, 0)
    etcd_endpoints          = "- ${join("\n    - ", var.etcd_endpoints)}"
    cert_sans               = "- ${element(var.connections, 0)}"
  }
}

data "template_file" "master" {
  template = file("${path.module}/scripts/master.sh")

  vars = {
    token = local.cluster_token
  }
}

data "template_file" "slave" {
  template = file("${path.module}/scripts/slave.sh")

  vars = {
    master_ip = element(var.vpn_ips, 0)
    token     = local.cluster_token
  }
}

data "template_file" "install" {
  count    = var.node_count
  template = file("${path.module}/scripts/install.sh")

  vars = {
    vpn_interface = var.vpn_interface
    overlay_cidr  = var.overlay_cidr
  }
}

output "overlay_interface" {
  value = var.overlay_interface
}

output "overlay_cidr" {
  value = var.overlay_cidr
}

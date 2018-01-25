variable "count" {}

variable "connections" {
  type = "list"
}

variable "vpn_ips" {
  type = "list"
}

variable "vpn_interface" {
  type = "string"
}

variable "etcd_endpoints" {
  type = "list"
}

variable "overlay_interface" {
  default = "weave"
}

variable "overlay_cidr" {
  default = "10.96.0.0/16"
}

resource "null_resource" "kubernetes" {
  count = "${var.count}"

  connection {
    host  = "${element(var.connections, count.index)}"
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
    inline = ["[ -d /etc/systemd/system/docker.service.d ] || mkdir -p /etc/systemd/system/docker.service.d"]
  }

  provisioner "file" {
    content     = "${file("${path.module}/templates/10-docker-opts.conf")}"
    destination = "/etc/systemd/system/docker.service.d/10-docker-opts.conf"
  }

  provisioner "file" {
    content     = "${data.template_file.master-configuration.rendered}"
    destination = "/tmp/master-configuration.yml"
  }

  provisioner "remote-exec" {
    inline = <<EOF
  ${element(data.template_file.install.*.rendered, count.index)}
  EOF
  }

  provisioner "remote-exec" {
    inline = <<EOF
${count.index == 0 ? data.template_file.master.rendered : data.template_file.slave.rendered}
EOF
  }
}

data "template_file" "master-configuration" {
  template = "${file("${path.module}/templates/master-configuration.yml")}"

  vars {
    api_advertise_addresses = "${element(var.vpn_ips, 0)}"
    etcd_endpoints          = "- ${join("\n  - ", var.etcd_endpoints)}"
    cert_sans               = "- ${element(var.connections, 0)}"
  }
}

data "template_file" "master" {
  template = "${file("${path.module}/scripts/master.sh")}"

  vars {
    token = "${data.external.cluster_token.result.token}"
  }
}

data "template_file" "slave" {
  template = "${file("${path.module}/scripts/slave.sh")}"

  vars {
    master_ip = "${element(var.vpn_ips, 0)}"
    token     = "${data.external.cluster_token.result.token}"
  }
}

data "template_file" "install" {
  count    = "${var.count}"
  template = "${file("${path.module}/scripts/install.sh")}"

  vars {
    vpn_interface = "${var.vpn_interface}"
    vpn_ip        = "${element(var.vpn_ips, count.index)}"
    overlay_cidr  = "${var.overlay_cidr}"
  }
}

data "external" "cluster_token" {
  program = ["sh", "${path.module}/scripts/gen_token.sh"]
}

output "overlay_interface" {
  value = "${var.overlay_interface}"
}

output "overlay_cidr" {
  value = "${var.overlay_cidr}"
}

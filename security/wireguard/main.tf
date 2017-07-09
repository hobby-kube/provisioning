variable "count" {}

variable "connections" {
  type = "list"
}

variable "private_ips" {
  type = "list"
}

variable "vpn_interface" {
  default = "wg0"
}

variable "vpn_port" {
  default = "51820"
}

variable "hostnames" {
  type = "list"
}

variable "vpn_iprange" {
  default = "10.0.1.0/24"
}

resource "null_resource" "wireguard" {
  count = "${var.count}"

  triggers {
    count = "${var.count}"
  }

  connection {
    host  = "${element(var.connections, count.index)}"
    user  = "root"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get install -yq software-properties-common python-software-properties build-essential",
      "add-apt-repository -y ppa:wireguard/wireguard",
      "apt-get update",
    ]
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/install-kernel-headers.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "DEBIAN_FRONTEND=noninteractive apt-get install -yq wireguard-dkms wireguard-tools",
    ]
  }

  provisioner "file" {
    content     = "${element(data.template_file.interface-conf.*.rendered, count.index)}"
    destination = "/etc/wireguard/${var.vpn_interface}.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 /etc/wireguard/${var.vpn_interface}.conf",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "${join("\n", formatlist("echo '%s %s' >> /etc/hosts", data.template_file.vpn_ips.*.rendered, var.hostnames))}",
      "systemctl is-enabled wg-quick@${var.vpn_interface} || systemctl enable wg-quick@${var.vpn_interface}",
      "systemctl restart wg-quick@${var.vpn_interface}",
    ]
  }
}

data "template_file" "interface-conf" {
  count    = "${var.count}"
  template = "${file("${path.module}/templates/interface.conf")}"

  vars {
    address     = "${element(data.template_file.vpn_ips.*.rendered, count.index)}"
    port        = "${var.vpn_port}"
    private_key = "${element(data.external.keys.*.result.private_key, count.index)}"
    peers       = "${replace(join("\n", data.template_file.peer-conf.*.rendered), element(data.template_file.peer-conf.*.rendered, count.index), "")}"
  }
}

data "template_file" "peer-conf" {
  count    = "${var.count}"
  template = "${file("${path.module}/templates/peer.conf")}"

  vars {
    endpoint    = "${element(var.private_ips, count.index)}"
    port        = "${var.vpn_port}"
    public_key  = "${element(data.external.keys.*.result.public_key, count.index)}"
    allowed_ips = "${element(data.template_file.vpn_ips.*.rendered, count.index)}/32"
  }
}

data "external" "keys" {
  count = "${var.count}"

  program = ["sh", "${path.module}/scripts/gen_keys.sh"]
}

data "template_file" "vpn_ips" {
  count    = "${var.count}"
  template = "$${ip}"

  vars {
    ip = "${cidrhost(var.vpn_iprange, count.index + 1)}"
  }
}

output "vpn_ips" {
  depends_on = ["null_resource.wireguard"]
  value      = ["${data.template_file.vpn_ips.*.rendered}"]
}

output "vpn_unit" {
  depends_on = ["null_resource.wireguard"]
  value      = "wg-quick@${var.vpn_interface}.service"
}

output "vpn_interface" {
  value = "${var.vpn_interface}"
}

output "vpn_port" {
  value = "${var.vpn_port}"
}

variable "count" {}

variable "connections" {
  type = "list"
}

variable "private_interface" {
  type = "string"
}

variable "vpn_interface" {
  type = "string"
}

variable "vpn_port" {
  type = "string"
}

variable "kubernetes_interface" {
  type = "string"
}

resource "null_resource" "firewall" {
  count = "${var.count}"

  triggers = {
    template = "${data.template_file.ufw.rendered}"
  }

  connection {
    host  = "${element(var.connections, count.index)}"
    user  = "root"
    agent = true
  }

  provisioner "remote-exec" {
    inline = <<EOF
${data.template_file.ufw.rendered}
EOF
  }
}

data "template_file" "ufw" {
  template = "${file("${path.module}/scripts/ufw.sh")}"

  vars {
    private_interface    = "${var.private_interface}"
    kubernetes_interface = "${var.kubernetes_interface}"
    vpn_interface        = "${var.vpn_interface}"
    vpn_port             = "${var.vpn_port}"
  }
}

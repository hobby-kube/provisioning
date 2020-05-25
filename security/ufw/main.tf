variable "node_count" {}

variable "connections" {
  type = list
}

variable "private_interface" {
  type = string
}

variable "vpn_interface" {
  type = string
}

variable "vpn_port" {
  type = string
}

variable "kubernetes_interface" {
  type = string
}

variable "additional_rules" {
  type    = list(string)
  default = []
}

resource "null_resource" "firewall" {
  count = var.node_count

  triggers = {
    template = data.template_file.ufw.rendered
  }

  connection {
    host  = element(var.connections, count.index)
    user  = "root"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      data.template_file.ufw.rendered
    ]
      
  }
}

data "template_file" "ufw" {
  template = file("${path.module}/scripts/ufw.sh")

  vars = {
    private_interface    = var.private_interface
    kubernetes_interface = var.kubernetes_interface
    vpn_interface        = var.vpn_interface
    vpn_port             = var.vpn_port
    additional_rules     = join("\nufw ", flatten(["", var.additional_rules]))
  }
}

variable "count" {}

variable "connections" {
  type = "list"
}

resource "null_resource" "swap" {
  count = "${var.count}"

  connection {
    host  = "${element(var.connections, count.index)}"
    user  = "root"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "fallocate -l 2G /swapfile",
      "chmod 600 /swapfile",
      "mkswap /swapfile",
      "swapon /swapfile",
      "echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/systemd/system/kubelet.service.d",
    ]
  }

  provisioner "file" {
    content     = "${file("${path.module}/templates/90-kubelet-extras.conf")}"
    destination = "/etc/systemd/system/kubelet.service.d/90-kubelet-extras.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl daemon-reload",
    ]
  }
}

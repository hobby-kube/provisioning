variable "node_count" {}

variable "connections" {
  type = list(any)
}

resource "null_resource" "swap" {
  count = var.node_count

  connection {
    host  = element(var.connections, count.index)
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
}

output "kubelet_extra_args" {
  value = "--fail-swap-on=false"
}

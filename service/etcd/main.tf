variable "node_count" {}

variable "connections" {
  type = list(any)
}

variable "hostnames" {
  type = list(any)
}

variable "vpn_unit" {
  type = string
}

variable "vpn_ips" {
  type = list(any)
}

locals {
  etcd_hostnames = slice(var.hostnames, 0, var.node_count)
  etcd_vpn_ips   = slice(var.vpn_ips, 0, var.node_count)
}

variable "etcd_version" {
  default = "v3.5.6"
}

resource "null_resource" "etcd" {
  count = var.node_count

  triggers = {
    template = join("", data.null_data_source.etcd-service.*.outputs.content)
  }

  connection {
    host  = element(var.connections, count.index)
    user  = "root"
    agent = true
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install.sh"
    destination = "/tmp/install-etcd.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-etcd.sh",
      "/tmp/install-etcd.sh '${var.etcd_version}'"
    ]
  }

  provisioner "file" {
    content     = element(data.null_data_source.etcd-service.*.outputs.content, count.index)
    destination = "/etc/systemd/system/etcd.service"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl is-enabled etcd.service || systemctl enable etcd.service",
      "systemctl daemon-reload",
      # etcd needs connectivity between nodes (e.g. via wireguard private IPs: `vpn_ips`) or else we
      # get startup errors like `listen tcp 10.0.1.2:2380: bind: cannot assign requested address`.
      # Therefore let systemd restart the service a few more times if necessary, and wait until it is running.
      "systemctl restart etcd.service || true",
      "for n in $(seq 1 20); do if systemctl is-active etcd.service; then exit 0; fi; sleep 5; done; echo 'etcd failed to start, latest status:'; systemctl --no-pager status etcd.service; echo; exit 1",
    ]
  }
}

data "null_data_source" "etcd-service" {
  count = var.node_count

  inputs = {
    content = templatefile("${path.module}/templates/etcd.service", {
      hostname              = element(local.etcd_hostnames, count.index)
      intial_cluster        = "${join(",", formatlist("%s=http://%s:2380", local.etcd_hostnames, local.etcd_vpn_ips))}"
      listen_client_urls    = "http://${element(local.etcd_vpn_ips, count.index)}:2379"
      advertise_client_urls = "http://${element(local.etcd_vpn_ips, count.index)}:2379"
      listen_peer_urls      = "http://${element(local.etcd_vpn_ips, count.index)}:2380"
      vpn_unit              = var.vpn_unit
    })
  }
}

data "null_data_source" "endpoints" {
  depends_on = [null_resource.etcd]

  inputs = {
    list = "${join(",", formatlist("http://%s:2379", local.etcd_vpn_ips))}"
  }
}

output "endpoints" {
  value = split(",", data.null_data_source.endpoints.outputs["list"])
}

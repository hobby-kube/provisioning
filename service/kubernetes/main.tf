variable "apiserver_extra_args" {
  type = map(any)

  default = {}
}

variable "apiserver_extra_volumes" {
  # Not specifying a `type` here since otherwise, Terraform may turn boolean values into strings
  # and the server will not start (e.g., `"readOnly" = true` becomes stringified by `yamlencode`).
  #
  # This is a list of volume definitions.
  # See https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/#kubeadm-k8s-io-v1beta3-ControlPlaneComponent

  default = []
}

variable "kubelet_extra_config" {
  # `map(any)` together with `yamlencode` might turn boolean values into strings, making the YAML
  # invalid, so we instead support verbatim YAML input
  type = string

  description = "Extra config appended to KubeletConfiguration. Only applies at cluster creation."
  default     = ""
}

variable "node_count" {}

variable "connections" {
  type = list(any)
}

variable "vpn_ips" {
  type = list(any)
}

variable "vpn_interface" {
  type = string
}

variable "etcd_endpoints" {
  type = list(any)
}

variable "overlay_interface" {
  default = "cilium_vxlan"
}

variable "overlay_cidr" {
  default = "10.96.0.0/16"
}

variable "cilium_version" {
  type    = string
  default = "1.16.0"
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
    content = templatefile("${path.module}/templates/master-configuration.yml", {
      api_advertise_address   = element(var.vpn_ips, 0)
      apiserver_extra_args    = yamlencode(var.apiserver_extra_args)
      apiserver_extra_volumes = yamlencode(var.apiserver_extra_volumes)
      etcd_endpoints          = "- ${join("\n    - ", var.etcd_endpoints)}"
      cert_sans               = "- ${element(var.connections, 0)}"
      kubelet_extra_config    = var.kubelet_extra_config
    })
    destination = "/tmp/master-configuration.yml"
  }

  provisioner "remote-exec" {
    inline = [
      file("${path.module}/scripts/install.sh")
    ]
  }

  provisioner "remote-exec" {
    inline = [
      count.index == 0
      ? templatefile("${path.module}/scripts/master.sh",
        {
          token          = local.cluster_token
          cilium_version = var.cilium_version
          overlay_cidr   = var.overlay_cidr
      })
      : templatefile("${path.module}/scripts/slave.sh",
        {
          master_ip = element(var.vpn_ips, 0)
          token     = local.cluster_token
      })
    ]
  }
}

output "overlay_interface" {
  value = var.overlay_interface
}

output "overlay_cidr" {
  value = var.overlay_cidr
}

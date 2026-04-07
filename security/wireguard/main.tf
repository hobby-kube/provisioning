variable "node_count" {}

variable "connections" {
  type = list(any)
}

variable "private_ips" {
  type = list(any)
}

variable "vpn_interface" {
  default = "wg0"
}

variable "vpn_port" {
  default = "51820"
}

variable "hostnames" {
  type = list(any)
}

variable "overlay_cidr" {
  type = string
}

variable "overlay_cidr_ipv6" {
  type    = string
  default = "" # empty means IPv6 is disabled
}

variable "vpn_iprange" {
  default = "10.0.1.0/24"
}

variable "vpn_iprange_ipv6" {
  # Default is empty, meaning dual-stack support is disabled.
  # Set to a ULA range like "fd00:10:0:1::/64" to enable dual-stack support.
  default = ""
}

resource "null_resource" "wireguard" {
  count = var.node_count

  triggers = {
    count = var.node_count
  }

  connection {
    host  = element(var.connections, count.index)
    user  = "root"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf",
      "%{if length(local.vpn_ips_ipv6) > 0}echo net.ipv6.conf.all.forwarding=1 >> /etc/sysctl.conf%{else}echo No IPv6%{endif}",

      "echo br_netfilter > /etc/modules-load.d/kubernetes.conf",
      "modprobe br_netfilter",
      "echo net.bridge.bridge-nf-call-iptables=1 >> /etc/sysctl.conf",

      "sysctl -p",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -yq wireguard",
    ]
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/interface.conf", {
      address      = element(local.vpn_ips, count.index)
      address_ipv6 = length(local.vpn_ips_ipv6) == 0 ? "" : element(local.vpn_ips_ipv6, count.index)
      port         = var.vpn_port
      private_key  = element(data.external.keys.*.result.private_key, count.index)
      peers = templatefile("${path.module}/templates/peer.conf", {
        exclude_index    = count.index
        endpoints        = var.private_ips
        port             = var.vpn_port
        public_keys      = data.external.keys.*.result.public_key
        allowed_ips      = local.vpn_ips
        allowed_ips_ipv6 = local.vpn_ips_ipv6
      })
    })
    destination = "/etc/wireguard/${var.vpn_interface}.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 /etc/wireguard/${var.vpn_interface}.conf",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "${join("\n", formatlist("echo '%s %s' >> /etc/hosts", local.vpn_ips, var.hostnames))}",
      "%{if length(local.vpn_ips_ipv6) > 0}${join("\n", formatlist("echo '%s %s' >> /etc/hosts", local.vpn_ips_ipv6, var.hostnames))}%{else}echo No IPv6%{endif}",
      "systemctl is-enabled wg-quick@${var.vpn_interface} || systemctl enable wg-quick@${var.vpn_interface}",
      "systemctl daemon-reload",
      "systemctl restart wg-quick@${var.vpn_interface}",
    ]
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/overlay-route.service", {
      address           = element(local.vpn_ips, count.index)
      address_ipv6      = length(local.vpn_ips_ipv6) > 0 ? element(local.vpn_ips_ipv6, count.index) : ""
      overlay_cidr      = var.overlay_cidr
      overlay_cidr_ipv6 = var.overlay_cidr_ipv6
    })
    destination = "/etc/systemd/system/overlay-route.service"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl is-enabled overlay-route.service || systemctl enable overlay-route.service",
      "systemctl daemon-reload",
      "systemctl start overlay-route.service",
    ]
  }
}

data "external" "keys" {
  count = var.node_count

  program = ["sh", "${path.module}/scripts/gen_keys.sh"]
}

locals {
  vpn_ips = [
    for n in range(var.node_count) :
    cidrhost(var.vpn_iprange, n + 1)
  ]
  vpn_ips_ipv6 = length(var.vpn_iprange_ipv6) == 0 ? [] : [
    for n in range(var.node_count) :
    cidrhost(var.vpn_iprange_ipv6, n + 1)
  ]
}

output "vpn_ips" {
  depends_on = [null_resource.wireguard]
  value      = local.vpn_ips
}

output "vpn_ips_ipv6" {
  depends_on = [null_resource.wireguard]
  value      = local.vpn_ips_ipv6
}

output "vpn_unit" {
  depends_on = [null_resource.wireguard]
  value      = "wg-quick@${var.vpn_interface}.service"
}

output "vpn_interface" {
  value = var.vpn_interface
}

output "vpn_port" {
  value = var.vpn_port
}

output "overlay_cidr" {
  value = var.overlay_cidr
}

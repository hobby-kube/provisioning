variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "hosts" {
  type = number
}

variable "hostname_format" {
  type = string
}

variable "zone" {
  type = string
}

variable "plan" {
  type = string
}

variable "disk_template" {
  type = string
}

variable "ssh_keys" {
  type = list(any)
}

variable "apt_packages" {
  type    = list(any)
  default = []
}

provider "upcloud" {
  username = var.username
  password = var.password
}

resource "upcloud_server" "host" {
  hostname = format(var.hostname_format, count.index + 1)
  zone     = var.zone
  plan     = var.plan

  count = var.hosts

  template {
    size    = lookup(var.storage_sizes, var.plan)
    storage = var.disk_template
  }

  network_interface {
    type = "public"
  }

  # network_interface {
  #   type = "private"
  #   network = upcloud_network.cluster_network.id
  # }

  login {
    user            = "root"
    keys            = var.ssh_keys
    create_password = false
  }

  connection {
    user    = "root"
    type    = "ssh"
    timeout = "2m"
    host    = self.network_interface[0].ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done",
      "apt-get update",
      "apt-get install -yq ufw ${join(" ", var.apt_packages)}",
    ]
  }
}

variable "storage_sizes" {
  type = map(any)
  default = {
    "1xCPU-1GB" = 25
    "1xCPU-2GB" = 50
    "2xCPU-4GB" = 80
  }
}

# resource "upcloud_storage" "storage" {
#   size  = 10
#   tier  = "maxiops"
#   title = format(var.hostname_format, count.index + 1)
#   zone  = var.zone
# 
#   backup_rule {
#     interval  = "daily"
#     time      = "0100"
#     retention = 8
#   }
# }

# resource "upcloud_network" "cluster_network" {
#   name = "cluster_network"
#   zone = "nl-ams1"
# 
#   ip_network {
#     address            = "10.0.0.0/24"
#     dhcp               = true
#     dhcp_default_route = false
#     family  = "IPv4"
#     gateway = "10.0.0.1"
#   }
# }

output "hostnames" {
  value = upcloud_server.host[*].hostname
}

output "public_ips" {
  value = upcloud_server.host[*].network_interface[0].ip_address
}

output "private_ips" {
  # [0] should be [1] if you have an actual private interface
  value = upcloud_server.host[*].network_interface[0].ip_address
}

output "private_network_interface" {
  value = "eth1"
}

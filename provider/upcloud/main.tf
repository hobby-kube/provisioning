variable "username" {
  default = ""
}

variable "password" {
  default = ""
}

variable "hosts" {
  default = 3
}

variable "hostname_format" {
  type = string
}

variable "zone" {
  type = string
}

variable "plan" {
  default = "1xCPU-1GB"
}

variable "disk_template" {
  default = "Ubuntu Server 20.04 LTS (Focal Fossa)"
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

  network_interface {
    type = "private"
  }

  login {
    user            = "root"
    keys            = var.ssh_keys
    create_password = false
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

output "hostnames" {
  value = upcloud_server.host[*].hostname
}

output "public_ips" {
  value = upcloud_server.host[*].network_interface[0].ip_address
}

output "private_ips" {
  value = upcloud_server.host[*].network_interface[1].ip_address
}

output "private_network_interface" {
  value = "eth1"
}

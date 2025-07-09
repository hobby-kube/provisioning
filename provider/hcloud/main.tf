variable "token" {}

variable "hosts" {
  default = 0
}

variable "hostname_format" {
  type = string
}

variable "location" {
  type        = string
  description = "Default datacenter location. Mutually exclusive with `locations` variable."
  default     = ""
}

variable "locations" {
  type        = list(string)
  description = "Per-host datacenter location. Mutually exclusive with `location` variable. Use this to provide mixed locations. The list must contain as many entries as specified by the `hosts` variable."
  default     = []
}

variable "type" {
  type        = string
  description = "Default server type. Mutually exclusive with `types` variable."
  default     = ""
}

variable "types" {
  type        = list(string)
  description = "Per-host server type. Mutually exclusive with `type` variable. Use this to provide mixed types. The list must contain as many entries as specified by the `hosts` variable."
  default     = []
}

variable "image" {
  type = string
}

variable "ssh_keys" {
  type = list(string)
}

provider "hcloud" {
  token = var.token
}

variable "apt_packages" {
  type    = list(string)
  default = []
}

resource "hcloud_server" "host" {
  name        = format(var.hostname_format, count.index + 1)
  location    = var.locations != [] ? element(var.locations, count.index) : var.location
  image       = var.image
  server_type = var.types != [] ? element(var.types, count.index) : var.type
  ssh_keys    = var.ssh_keys

  count = var.hosts

  connection {
    user    = "root"
    type    = "ssh"
    timeout = "2m"
    host    = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done",
      "apt-get update",
      "apt-get install -yq ufw ${join(" ", var.apt_packages)}",
    ]
  }
}

# resource "hcloud_volume" "volume" {
#   name      = format(var.hostname_format, count.index + 1)
#   size      = 10
#   server_id = element(hcloud_server.host.*.id, count.index)
#   automount = false

#   count = var.hosts
# }

output "hostnames" {
  value = hcloud_server.host.*.name
}

output "public_ips" {
  value = hcloud_server.host.*.ipv4_address
}

output "private_ips" {
  value = hcloud_server.host.*.ipv4_address
}

output "private_network_interface" {
  value = "eth0"
}

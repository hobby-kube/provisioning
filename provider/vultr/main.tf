variable "api_key" {}

variable "rate_limit" {
  default = 700
}

variable "retry_limit" {
  default = 3
}

variable "hosts" {
  default = 0
}

variable "hostname_format" {
  type = string
}

variable "region_id" {
  type = string
}

variable "plan_id" {
  type = string
}

variable "os_id" {
  type = string
}

variable "ssh_key_ids" {
  type = list(string)
}

variable "apt_packages" {
  type    = list(string)
  default = []
}

provider "vultr" {
  api_key      = var.api_key
  rate_limit   = var.rate_limit
  retry_limit  = var.retry_limit
}

resource "vultr_server" "host" {
  count        = var.hosts
  hostname     = format(var.hostname_format, count.index + 1)
  label        = format(var.hostname_format, count.index + 1)
  region_id    = var.region_id
  os_id        = var.os_id
  plan_id      = var.plan_id
  ssh_key_ids  = var.ssh_key_ids

  connection {
    user = "root"
    type = "ssh"
    timeout = "2m"
    host = self.main_ip
  }

  provisioner "remote-exec" {
    inline = [
      "while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done",
      "apt-get update",
      "apt-get install -yq ufw ${join(" ", var.apt_packages)}",
    ]
  }
}

output "public_ips" {
  value = vultr_server.host.*.main_ip
}

output "hostnames" {
  value = vultr_server.host.*.hostname
}

output "private_ips" {
  value = vultr_server.host.*.main_ip
}

output "private_network_interface" {
  value = "$(ifconfig -s | grep -E '^ens\\w+' | cut -d' ' -f1)"
}

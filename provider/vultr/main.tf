variable "api_key" {}

variable "rate_limit" {
  /*
    > https://www.terraform.io/docs/providers/vultr/index.html
    > Vultr limits API calls to 3 calls per second. This field lets you
    > configure how the rate limit using milliseconds. The default value
    > if this field is omitted is 650 milliseconds per call.

    If you are facing an error like this
      ```
      Error: Error getting private networks
      for server  37329555 : gave up after 4 attempts, last error:
      "Rate limit reached - please try your request again later.
      Current rate limit: 3 requests/sec"
      ```
    try increasing the vultr_rate_limit value. For example, the default value
    is not enough for a cluster of 10 nodes, but rate_limit = 4000
    works fine for the case.
  */
  default = 650
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

variable "region" {
  type = string
}

variable "plan" {
  type = string
}

variable "os" {
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

data "vultr_region" "region" {
  filter {
    name = "name"
    values = [ var.region ]
  }
}

data "vultr_plan" "plan" {
  filter {
    name = "name"
    values = [ var.plan ]
  }
}

data "vultr_os" "os" {
  filter {
    name = "name"
    values = [ var.os ]
  }
}

resource "vultr_server" "host" {
  count        = var.hosts
  hostname     = format(var.hostname_format, count.index + 1)
  label        = format(var.hostname_format, count.index + 1)
  region_id    = data.vultr_region.region.id
  os_id        = data.vultr_os.os.id
  plan_id      = data.vultr_plan.plan.id
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

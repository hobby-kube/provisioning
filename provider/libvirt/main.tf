variable "hosts" {
  default = 0
}

variable "disk_size_gb" {
  default = 50
}

variable "memory_mb" {
  default = 1024
}

variable "vcpus" {
  default = 1
}

variable "image_source" {
  type = string
  default = "https://cloud-images.ubuntu.com/releases/bionic/release-20200922/ubuntu-18.04-server-cloudimg-amd64.img"
  # 2020-10-18: Lastest release 20201014 has issues with booting
}

variable "basename" {
  type = string
  default = "hobbykube"
}

variable "ssh_keys" {
  type    = list
  default = []
}

variable "ssh_keys_github_username" {
  default = ""
}

variable "apt_packages" {
  type    = list
  default = []
}

variable "do_package_upgrade" {
  type    = string
  default = "false"
}

variable "hostname_format" {
  type    = string
  default = "kube%d"
}

variable "libvirt_connection_uri" {
  type    = string
  default = "qemu:///system"
}

variable "public_gateway" {
  type    = string
  default = ""
}

variable "public_nameserver" {
  type    = string
  default = ""
}

variable "public_iprange" {
  type    = string
  default = ""
}

variable "public_iprange_offset" {
  default = 1
}

locals {
  user_data = [
    for n in range(var.hosts) : templatefile("${path.module}/templates/cloud_init.cfg", {
      hostname   = element(data.template_file.hostnames.*.rendered, n)
      keys       = var.ssh_keys_github_username == "" ? var.ssh_keys : data.github_user.ssh_keys_user.ssh_keys
      do_upgrade = var.do_package_upgrade
    })
  ]
}

provider "libvirt" {
  uri = var.libvirt_connection_uri
}

resource "libvirt_pool" "storage_pool" {
  name = "${var.basename}-pool"
  type = "dir"
  path = "/var/lib/libvirt/images/${var.basename}-pool"
}

resource "libvirt_volume" "os_image" {
  name = "${var.basename}-baseimage-ubuntu-qcow2"
  pool = libvirt_pool.storage_pool.name
  source = var.image_source
  format = "qcow2"
}

resource "libvirt_volume" "volume" {
  count          = var.hosts
  name           = "${var.basename}-volume-${element(data.template_file.hostnames.*.rendered, count.index)}"
  pool           = libvirt_pool.storage_pool.name
  base_volume_id = libvirt_volume.os_image.id
  size           = var.disk_size_gb * 1024 * 1024 * 1024
}

resource "libvirt_cloudinit_disk" "commoninit" {
  count          = var.hosts
  name           = "${element(data.template_file.hostnames.*.rendered, count.index)}-commoninit.iso"
  user_data      = element(local.user_data, count.index)
  network_config = element(data.template_file.network_config.*.rendered, count.index)
  pool           = libvirt_pool.storage_pool.name
}

resource "libvirt_domain" "node_domain" {
  count  = var.hosts
  name   = "${var.basename}-${element(data.template_file.hostnames.*.rendered, count.index)}"
  memory = var.memory_mb
  vcpu   = var.vcpus

  cloudinit = element(libvirt_cloudinit_disk.commoninit.*.id, count.index)

  network_interface {
    bridge = "br0"
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = element(libvirt_volume.volume.*.id, count.index)
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  connection {
    user    = "root"
    type    = "ssh"
    timeout = "2m"
    host    = element(data.template_file.public_ips.*.rendered, count.index)
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait  > /dev/null 2>&1",
      "DEBIAN_FRONTEND=noninteractive apt-get install -yq ufw ${join(" ", var.apt_packages)}",
    ]
  }

}

data "github_user" "ssh_keys_user" {
  username = var.ssh_keys_github_username == "" ? "github" : var.ssh_keys_github_username
}

data "template_file" "public_ips" {
  count    = var.hosts
  template = "$${ip}"

  vars = {
    ip = cidrhost(var.public_iprange, count.index + var.public_iprange_offset)
  }
}

data "template_file" "hostnames" {
  count    = var.hosts
  template = "$${name}"

  vars = {
    name = format(var.hostname_format, count.index + 1)
  }
}

data "template_file" "network_config" {
  count    = var.hosts
  template = file("${path.module}/templates/network_config.cfg")

  vars = {
    address    = element(data.template_file.public_ips.*.rendered, count.index)
    gateway    = var.public_gateway
    nameserver = var.public_nameserver
  }
}

output "hostnames" {
  value = "${template_file.hostnames.*.rendered}"
}

output "public_ips" {
  value = "${data.template_file.public_ips.*.rendered}"
}

output "private_ips" {
  value = "${data.template_file.public_ips.*.rendered}"
}

output "private_network_interface" {
  value = "ens3"
}

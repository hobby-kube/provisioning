variable "hosts" {
  default = 0
}

variable "hostname_format" {
  type = string
}

variable "apt_packages" {
  type    = list
  default = []
}

variable "vsphere_server" {
    description = "vsphere server for the environment - EXAMPLE: vcenter01.hosted.local"
}
 
variable "vsphere_user" {
    description = "vsphere server for the environment - EXAMPLE: vsphereuser"
}
 
variable "vsphere_password" {
    description = "vsphere server password for the environment"
}

# Set vsphere datacenter
variable "vsphere_datacenter" {
}
# Set cluster where you want deploy your vm
variable "vsphere_cluster" {
}

variable "vsphere_network" {
}

variable "vsphere_datastore" {
}

variable "vsphere_vm_template" {
}

variable "vsphere_vm_linked_clone" {

}

variable "vsphere_vm_num_cpus" {
}

variable "vsphere_vm_memory" {
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}
 
data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}
 
data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template_linux" {
  name          = var.vsphere_vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server
 
  # if you have a self-signed cert
  allow_unverified_ssl = true

}


resource "vsphere_virtual_machine" "host" {
  count = var.hosts
  name              = format(var.hostname_format, count.index + 1)
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
 
  num_cpus = var.vsphere_vm_num_cpus
  num_cores_per_socket = var.vsphere_vm_num_cpus
  memory   = var.vsphere_vm_memory
  memory_reservation = var.vsphere_vm_memory
  guest_id = data.vsphere_virtual_machine.template_linux.guest_id
 
  scsi_type = data.vsphere_virtual_machine.template_linux.scsi_type
 
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template_linux.network_interface_types[0]
  }

  wait_for_guest_net_timeout = 200
 
  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template_linux.disks.0.size
  }
 
  clone {
    template_uuid = data.vsphere_virtual_machine.template_linux.id
    linked_clone = var.vsphere_vm_linked_clone
  }

  connection {
    type = "ssh"
    user = "root"
    host = self.default_ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "hostnamectl set-hostname '${format(var.hostname_format, count.index + 1)}'",
      "apt-get update",
      "apt-get install -yq apt-transport-https curl ufw ${join(" ", var.apt_packages)}",
      "DEBIAN_FRONTEND=noninteractive apt-get install -yq -o Dpkg::Options::=--force-confnew sudo",
      ]
  }

}



output "hostnames" {
  value = "${vsphere_virtual_machine.host.*.name}"
}

output "public_ips" {
  value = "${vsphere_virtual_machine.host.*.default_ip_address}"
}

output "private_ips" {
  value = "${vsphere_virtual_machine.host.*.default_ip_address}"
}

output "private_network_interface" {
  value = "ens192"
}

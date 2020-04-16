/* general */
variable "node_count" {
  default = 3
}

/* etcd_node_count must be <= node_count; odd numbers provide quorum */
variable "etcd_node_count" {
  default = 3
}

variable "domain" {
  default = "example.com"
}

variable "hostname_format" {
  default = "kube%d"
}

/* hcloud */
variable "hcloud_token" {
  default = ""
}

variable "hcloud_ssh_keys" {
  type    = list(string)
  default = [""]
}

variable "hcloud_location" {
  default = "nbg1"
}

variable "hcloud_type" {
  default = "cx11"
}

variable "hcloud_image" {
  default = "ubuntu-18.04"
}

/* scaleway */
variable "scaleway_organization_id" {
  default = ""
}

variable "scaleway_access_key" {
  default = "SCWXXXXXXXXXXXXXXXXX" // enables to specify only the secret_key
}

variable "scaleway_secret_key" {
  default = ""
}

variable "scaleway_zone" {
  default = "nl-ams-1"
}

variable "scaleway_type" {
  default = "DEV1-S"
}

variable "scaleway_image" {
  default = "Ubuntu Bionic"
}

/* digitalocean */
variable "digitalocean_token" {
  default = ""
}

variable "digitalocean_ssh_keys" {
  type    = list(string)
  default = [""]
}

variable "digitalocean_region" {
  default = "fra1"
}

variable "digitalocean_size" {
  default = "1gb"
}

variable "digitalocean_image" {
  default = "ubuntu-18-04-x64"
}

/* packet */

variable "packet_auth_token" {
  default = ""
}

variable "packet_project_id" {
  default = ""
}

variable "packet_plan" {
  default = "c1.small.x86"
}

variable "packet_facility" {
  default = "sjc1"
}

variable "packet_operating_system" {
  default = "ubuntu_18_04"
}

variable "packet_billing_cycle" {
  default = "hourly"
}

variable "packet_user_data" {
  default = ""
}

/* aws dns */
variable "aws_access_key" {
  default = ""
}

variable "aws_secret_key" {
  default = ""
}

variable "aws_region" {
  default = "eu-west-1"
}

/* cloudflare dns */
variable "cloudflare_email" {
  default = ""
}

variable "cloudflare_api_token" {
  default = ""
}

/* google dns */
variable "google_project" {
  default = ""
}

variable "google_region" {
  default = ""
}

variable "google_managed_zone" {
  default = ""
}

variable "google_credentials_file" {
  default = ""
}

/* vsphere */

variable "vsphere_server" {
  description = "vsphere server for the environment - EXAMPLE: vcenter01.hosted.local or IP address"
  default = ""
}

variable "vsphere_datacenter" {
  description = "vSphere Datacenter Name"
  default = "Datacenter1"
}

variable "vsphere_cluster" {
  description = "vSphere Cluster Name"
  default = "Cluster1"
}

variable "vsphere_network" {
  description = "vSphere Network Name"
  default = "VM Network"
}

variable "vsphere_datastore" {
  description = "vSphere Datastore Name"
  default = "datastore1"
}

variable "vsphere_vm_template" {
  description = "vSphere VM Template Name"
  default = "tpl-ubuntu-1804"
}

variable "vsphere_vm_linked_clone" {
  description = "create vsphere linked clone VM"
  default = false
}

variable "vsphere_vm_num_cpus" {
  description = "Number of CPUs for the VM"
  default = "2"
}

variable "vsphere_vm_memory" {
  description = "Amount of memory for the VM"
  default = "2048"
}

variable "vsphere_user" {
  description = "vSphere Admin Username"
  default = "administrator@vsphere.local"
}

variable "vsphere_password" {
  description = "vSphere Admin Password"
  default = "YourSecretPassword"
}
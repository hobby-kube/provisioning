module "provider" {
  source = "./provider/hcloud"

  token           = var.hcloud_token
  ssh_keys        = var.hcloud_ssh_keys
  location        = var.hcloud_location
  type            = var.hcloud_type
  image           = var.hcloud_image
  hosts           = var.node_count
  hostname_format = var.hostname_format
}

# module "provider" {
#   source = "./provider/scaleway"
#
#   organization_id    = var.scaleway_organization_id
#   access_key         = var.scaleway_access_key
#   secret_key         = var.scaleway_secret_key
#   zone               = var.scaleway_zone
#   type               = var.scaleway_type
#   image              = var.scaleway_image
#   image_architecture = var.scaleway_image_architecture
#   hosts              = var.node_count
#   hostname_format    = var.hostname_format
# }

# module "provider" {
#   source = "./provider/digitalocean"
#
#   token           = var.digitalocean_token
#   ssh_keys        = var.digitalocean_ssh_keys
#   region          = var.digitalocean_region
#   size            = var.digitalocean_size
#   image           = var.digitalocean_image
#   hosts           = var.node_count
#   hostname_format = var.hostname_format
# }

# module "provider" {
#   source = "./provider/packet"
#
#   auth_token       = var.packet_auth_token
#   project_id       = var.packet_project_id
#   billing_cycle    = var.packet_billing_cycle
#   facility         = [var.packet_facility]
#   plan             = var.packet_plan
#   operating_system = var.packet_operating_system
#   hosts            = var.node_count
#   hostname_format  = var.hostname_format
# }

# module "provider" {
#   source = "./provider/vsphere"
#
#   hosts                   = var.node_count
#   hostname_format         = var.hostname_format
#   vsphere_server          = var.vsphere_server
#   vsphere_datacenter      = var.vsphere_datacenter
#   vsphere_cluster         = var.vsphere_cluster
#   vsphere_network         = var.vsphere_network
#   vsphere_datastore       = var.vsphere_datastore
#   vsphere_vm_template     = var.vsphere_vm_template
#   vsphere_vm_linked_clone = var.vsphere_vm_linked_clone
#   vsphere_vm_num_cpus     = var.vsphere_vm_num_cpus
#   vsphere_vm_memory       = var.vsphere_vm_memory
#   vsphere_user            = var.vsphere_user
#   vsphere_password        = var.vsphere_password
# }

# module "provider" {
#   source = "./provider/upcloud"
#
#   username        = var.upcloud_username
#   password        = var.upcloud_password
#   hosts           = var.node_count
#   hostname_format = var.hostname_format
#   zone            = var.upcloud_zone
#   plan            = var.upcloud_plan
#   disk_template   = var.upcloud_disk_template
#   ssh_keys        = var.upcloud_ssh_keys
# }

module "swap" {
  source = "./service/swap"

  node_count  = var.node_count
  connections = module.provider.public_ips
}

module "dns" {
  source = "./dns/cloudflare"

  node_count = var.node_count
  api_token  = var.cloudflare_api_token
  domain     = var.domain
  public_ips = module.provider.public_ips
  hostnames  = module.provider.hostnames
}

# module "dns" {
#   source = "./dns/aws"
#
#   node_count = var.node_count
#   access_key = var.aws_access_key
#   secret_key = var.aws_secret_key
#   region     = var.aws_region
#   domain     = var.domain
#   public_ips = module.provider.public_ips
#   hostnames  = module.provider.hostnames
# }

# module "dns" {
#   source = "./dns/google"
#
#   node_count   = var.node_count
#   project      = var.google_project
#   region       = var.google_region
#   creds_file   = var.google_credentials_file
#   managed_zone = var.google_managed_zone
#   domain       = var.domain
#   public_ips   = module.provider.public_ips
#   hostnames    = module.provider.hostnames
# }

# module "dns" {
#   source     = "./dns/digitalocean"
#
#   node_count = var.node_count
#   token      = var.digitalocean_token
#   domain     = var.domain
#   public_ips = module.provider.public_ips
#   hostnames  = module.provider.hostnames
# }

module "wireguard" {
  source = "./security/wireguard"

  node_count   = var.node_count
  connections  = module.provider.public_ips
  private_ips  = module.provider.private_ips
  hostnames    = module.provider.hostnames
  overlay_cidr = module.kubernetes.overlay_cidr
}

module "firewall" {
  source = "./security/ufw"

  node_count           = var.node_count
  connections          = module.provider.public_ips
  private_interface    = module.provider.private_network_interface
  vpn_interface        = module.wireguard.vpn_interface
  vpn_port             = module.wireguard.vpn_port
  kubernetes_interface = module.kubernetes.overlay_interface
}

module "etcd" {
  source = "./service/etcd"

  node_count  = var.etcd_node_count
  connections = module.provider.public_ips
  hostnames   = module.provider.hostnames
  vpn_unit    = module.wireguard.vpn_unit
  vpn_ips     = module.wireguard.vpn_ips
}

module "kubernetes" {
  source = "./service/kubernetes"

  node_count     = var.node_count
  connections    = module.provider.public_ips
  cluster_name   = var.domain
  vpn_interface  = module.wireguard.vpn_interface
  vpn_ips        = module.wireguard.vpn_ips
  etcd_endpoints = module.etcd.endpoints
}

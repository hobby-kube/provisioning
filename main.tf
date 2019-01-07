module "provider" {
  source = "./provider/hcloud"

  project_name    = "demo"
  token           = "${var.hcloud_token}"
  #ssh_keys        = "${var.hcloud_ssh_keys}"
  location        = "${var.hcloud_location}"
  type            = "${var.hcloud_type}"
  image           = "${var.hcloud_image}"
  hosts           = "${var.node_count}"
  #hostname_format = "${var.hostname_format}"
}

# module "provider" {
#   source = "./provider/scaleway"
#
#   organization    = "${var.scaleway_organization}"
#   token           = "${var.scaleway_token}"
#   region          = "${var.scaleway_region}"
#   type            = "${var.scaleway_type}"
#   image           = "${var.scaleway_image}"
#   hosts           = "${var.node_count}"
#   hostname_format = "${var.hostname_format}"
# }

# module "provider" {
#   source = "./provider/digitalocean"
#
#   token           = "${var.digitalocean_token}"
#   ssh_keys        = "${var.digitalocean_ssh_keys}"
#   region          = "${var.digitalocean_region}"
#   size            = "${var.digitalocean_size}"
#   image           = "${var.digitalocean_image}"
#   hosts           = "${var.node_count}"
#   hostname_format = "${var.hostname_format}"
# }

module "swap" {
  source = "./service/swap"

  count       = "${var.node_count}"
  connections = "${module.provider.public_ips}"
}

#module "dns" {
#  source = "./dns/cloudflare"

#  count      = "${var.node_count}"
#  email      = "${var.cloudflare_email}"
#  token      = "${var.cloudflare_token}"
#  domain     = "${var.domain}"
#  public_ips = "${module.provider.public_ips}"
#  hostnames  = "${module.provider.hostnames}"
#}

# module "dns" {
#   source = "./dns/aws"
#
#   count      = "${var.node_count}"
#   access_key = "${var.aws_access_key}"
#   secret_key = "${var.aws_secret_key}"
#   region     = "${var.aws_region}"
#   domain     = "${var.domain}"
#   public_ips = "${module.provider.public_ips}"
#   hostnames  = "${module.provider.hostnames}"
# }

# module "dns" {
#   source = "./dns/google"
#
#   count        = "${var.node_count}"
#   project      = "${var.google_project}"
#   region       = "${var.google_region}"
#   creds_file   = "${var.google_credentials_file}"
#   managed_zone = "${var.google_managed_zone}"
#   domain       = "${var.domain}"
#   public_ips   = "${module.provider.public_ips}"
#   hostnames    = "${module.provider.hostnames}"
# }

# module "dns" {
#   source     = "./dns/digitalocean"
#
#   count      = "${var.node_count}"
#   token      = "${var.digitalocean_token}"
#   domain     = "${var.domain}"
#   public_ips = "${module.provider.public_ips}"
#   hostnames  = "${module.provider.hostnames}"
# }

module "wireguard" {
  source = "./security/wireguard"

  count        = "${var.node_count}"
  connections  = "${module.provider.public_ips}"
  private_ips  = "${module.provider.private_ips}"
  hostnames    = "${module.provider.hostnames}"
  overlay_cidr = "${module.kubernetes.overlay_cidr}"
}

module "firewall" {
  source = "./security/ufw"

  count                = "${var.node_count}"
  connections          = "${module.provider.public_ips}"
  private_interface    = "${module.provider.private_network_interface}"
  vpn_interface        = "${module.wireguard.vpn_interface}"
  vpn_port             = "${module.wireguard.vpn_port}"
  kubernetes_interface = "${module.kubernetes.overlay_interface}"
}

module "etcd" {
  source = "./service/etcd"

  count       = "${var.node_count}"
  connections = "${module.provider.public_ips}"
  hostnames   = "${module.provider.hostnames}"
  vpn_unit    = "${module.wireguard.vpn_unit}"
  vpn_ips     = "${module.wireguard.vpn_ips}"
}

module "kubernetes" {
  source = "./service/kubernetes"

  count          = "${var.node_count}"
  connections    = "${module.provider.public_ips}"
  cluster_name   = "${var.domain}"
  vpn_interface  = "${module.wireguard.vpn_interface}"
  vpn_ips        = "${module.wireguard.vpn_ips}"
  etcd_endpoints = "${module.etcd.endpoints}"
}

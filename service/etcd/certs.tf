variable "certificates_validity_hours" {
  default = 87600 # 10 years
}

variable "certificates_directory" {
  default = "/etc/etcd"
}

locals {
  ca_certificate     = "${var.certificates_directory}/etcd-ca.pem"
  client_certificate = "${var.certificates_directory}/client.pem"
  client_key         = "${var.certificates_directory}/client.key"
  server_certificate = "${var.certificates_directory}/server.pem"
  server_key         = "${var.certificates_directory}/server.key"
  peer_certificate   = "${var.certificates_directory}/peer.pem"
  peer_key           = "${var.certificates_directory}/peer.key"

  ip_addresses = ["127.0.0.1", "${var.vpn_ips}"]
  dns_names    = ["localhost", "${var.hostnames}"]
}

resource "null_resource" "etcd-certs" {
  count = "${var.count}"

  connection {
    host  = "${element(var.connections, count.index)}"
    user  = "root"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ${var.certificates_directory}",
    ]
  }

  provisioner "file" {
    content     = "${tls_self_signed_cert.etcd-ca.cert_pem}"
    destination = "${local.ca_certificate}"
  }

  provisioner "file" {
    content     = "${tls_locally_signed_cert.client.cert_pem}"
    destination = "${local.client_certificate}"
  }

  provisioner "file" {
    content     = "${tls_private_key.client.private_key_pem}"
    destination = "${local.client_key}"
  }

  provisioner "file" {
    content     = "${tls_locally_signed_cert.server.cert_pem}"
    destination = "${local.server_certificate}"
  }

  provisioner "file" {
    content     = "${tls_private_key.server.private_key_pem}"
    destination = "${local.server_key}"
  }

  provisioner "file" {
    content     = "${tls_locally_signed_cert.peer.cert_pem}"
    destination = "${local.peer_certificate}"
  }

  provisioner "file" {
    content     = "${tls_private_key.peer.private_key_pem}"
    destination = "${local.peer_key}"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod -R 600 ${var.certificates_directory}/*.key",
    ]
  }
}

resource "tls_private_key" "etcd-ca" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "etcd-ca" {
  key_algorithm   = "${tls_private_key.etcd-ca.algorithm}"
  private_key_pem = "${tls_private_key.etcd-ca.private_key_pem}"

  subject {
    common_name  = "etcd-ca"
    organization = "etcd"
  }

  is_ca_certificate     = true
  validity_period_hours = "${var.certificates_validity_hours}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

resource "tls_private_key" "client" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "client" {
  key_algorithm   = "${tls_private_key.client.algorithm}"
  private_key_pem = "${tls_private_key.client.private_key_pem}"

  subject {
    common_name  = "etcd-client"
    organization = "etcd"
  }

  ip_addresses = ["${local.ip_addresses}"]
  dns_names    = ["${local.dns_names}"]
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem = "${tls_cert_request.client.cert_request_pem}"

  ca_key_algorithm   = "${join(" ", tls_self_signed_cert.etcd-ca.*.key_algorithm)}"
  ca_private_key_pem = "${join(" ", tls_private_key.etcd-ca.*.private_key_pem)}"
  ca_cert_pem        = "${join(" ", tls_self_signed_cert.etcd-ca.*.cert_pem)}"

  validity_period_hours = "${var.certificates_validity_hours}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "server" {
  key_algorithm   = "${tls_private_key.server.algorithm}"
  private_key_pem = "${tls_private_key.server.private_key_pem}"

  subject {
    common_name  = "etcd-server"
    organization = "etcd"
  }

  ip_addresses = ["${local.ip_addresses}"]
  dns_names    = ["${local.dns_names}"]
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem = "${tls_cert_request.server.cert_request_pem}"

  ca_key_algorithm   = "${join(" ", tls_self_signed_cert.etcd-ca.*.key_algorithm)}"
  ca_private_key_pem = "${join(" ", tls_private_key.etcd-ca.*.private_key_pem)}"
  ca_cert_pem        = "${join(" ", tls_self_signed_cert.etcd-ca.*.cert_pem)}"

  validity_period_hours = "${var.certificates_validity_hours}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
    "server_auth",
  ]
}

resource "tls_private_key" "peer" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "peer" {
  key_algorithm   = "${tls_private_key.peer.algorithm}"
  private_key_pem = "${tls_private_key.peer.private_key_pem}"

  subject {
    common_name  = "etcd-peer"
    organization = "etcd"
  }

  ip_addresses = ["${local.ip_addresses}"]
  dns_names    = ["${local.dns_names}"]
}

resource "tls_locally_signed_cert" "peer" {
  cert_request_pem = "${tls_cert_request.peer.cert_request_pem}"

  ca_key_algorithm   = "${join(" ", tls_self_signed_cert.etcd-ca.*.key_algorithm)}"
  ca_private_key_pem = "${join(" ", tls_private_key.etcd-ca.*.private_key_pem)}"
  ca_cert_pem        = "${join(" ", tls_self_signed_cert.etcd-ca.*.cert_pem)}"

  validity_period_hours = "${var.certificates_validity_hours}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

output "ca_certificate" {
  value = "${local.ca_certificate}"
}

output "client_certificate" {
  value = "${local.client_certificate}"
}

output "client_key" {
  value = "${local.client_key}"
}

output "server_certificate" {
  value = "${local.server_certificate}"
}

output "server_key" {
  value = "${local.server_key}"
}

output "peer_certificate" {
  value = "${local.peer_certificate}"
}

output "peer_key" {
  value = "${local.peer_key}"
}

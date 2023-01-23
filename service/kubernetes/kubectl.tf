variable "cluster_name" {
  type = string
}

variable "api_secure_port" {
  default = "6443"
}

variable "kubeconfig_file" {
  type = string

  # Defaults to overwriting the default file (typically `~/.kube/config`, but the environment
  # variable `KUBECONFIG` overrides that so you may overwrite a file accidentally).
  #
  # If you want to store the kubeconfig configuration in a separate file, specify the file path.
  # Only in that case, the file will be deleted upon `terraform destroy`.
  default = ""
}

resource "null_resource" "kubectl" {
  depends_on = [null_resource.kubernetes]

  triggers = {
    ip = element(var.vpn_ips, 0)

    # `when = destroy` provisioner does not allow using variables/locals directly, so work around that
    kubeconfig_file = var.kubeconfig_file
  }

  provisioner "local-exec" {
    command = "[ -d $HOME/.kube/${var.cluster_name} ] || mkdir -p $HOME/.kube/${var.cluster_name}"
  }

  provisioner "local-exec" {
    command = <<EOT
      scp -oStrictHostKeyChecking=no \
        root@"${element(var.connections, 0)}":/etc/kubernetes/pki/{apiserver-kubelet-client.key,apiserver-kubelet-client.crt,ca.crt} \
        $HOME/.kube/${var.cluster_name}
EOT
  }

  provisioner "local-exec" {
    command = <<EOT
      if [ -n "${var.kubeconfig_file}" ]; then
        export KUBECONFIG="${var.kubeconfig_file}"
      fi

      kubectl config set-cluster ${var.cluster_name} \
      --certificate-authority=$HOME/.kube/${var.cluster_name}/ca.crt \
      --server=https://${element(var.connections, 0)}:${var.api_secure_port} \
      --embed-certs=true

      kubectl config set-credentials ${var.cluster_name}-admin \
        --client-key=$HOME/.kube/${var.cluster_name}/apiserver-kubelet-client.key \
        --client-certificate=$HOME/.kube/${var.cluster_name}/apiserver-kubelet-client.crt \
        --embed-certs=true

      kubectl config set-context ${var.cluster_name} \
        --cluster=${var.cluster_name} \
        --user=${var.cluster_name}-admin

      kubectl config use-context ${var.cluster_name}
      kubectl get nodes
EOT
  }

  provisioner "local-exec" {
    command = "rm -rf $HOME/.kube/${var.cluster_name}"
  }

  provisioner "local-exec" {
    when = destroy

    command = <<EOT
      if [ -n "${self.triggers.kubeconfig_file}" ]; then
        set -x
        rm -fv "${self.triggers.kubeconfig_file}"
      fi
EOT
  }
}

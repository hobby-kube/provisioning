variable "count" {}
variable "dependency" {
  type = "list"
}

variable "connections" {
  type = "list"
}

variable "theme" {
  type = "string"
}
variable "plugins" {
  type = "list"
}

resource "null_resource" "zsh" {
  count = "${var.count}"

  connection {
    host  = "${element(var.connections, count.index)}" # execute on all nodes
    user  = "root"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "rm -rf /root/.oh-my-zsh",
      "echo ${join(",", var.dependency)} > /dev/null",
      "curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh > /tmp/ohmyz.sh",
      "sed -i 's|env zsh|#env zsh|' /tmp/ohmyz.sh",
      "sed -i 's|git clone|git clone -q|' /tmp/ohmyz.sh",
      "sed -i 's|git clone|git clone -q|' /tmp/ohmyz.sh",
      "chmod u+x /tmp/ohmyz.sh",
      ". /tmp/ohmyz.sh",
      "sed -i 's|ZSH_THEME=\".*\"|ZSH_THEME=\"${var.theme}\"|' /root/.zshrc",
      "sed -i 's|^plugins=(|plugins=(\\n  ${join("\\n  ", var.plugins)}|' /root/.zshrc"
    ]
  }
}

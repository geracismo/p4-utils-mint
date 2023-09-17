variable "memory" {
  default = 4096
}

variable "cpus" {
  default = 4
}

variable "disk_size" {
  default = 25000
}

variable "vm_name" {
  default = "p4"
}

variable "username" {
  default = "p4"
}

variable "password" {
  default = "p4"
}

variable "iso_url" {
  default = "https://releases.ubuntu.com/20.04.6/ubuntu-20.04.6-live-server-amd64.iso"
}

variable "iso_checksum" {
  default = "sha256:b8f31413336b9393ad5d8ef0282717b2ab19f007df2e9ed5196c13d8f9153c8b"
}

variable "target" {
  default = "sources.qemu.ubuntu20046_qemu"
}

packer {
  required_plugins {
    qemu = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "ubuntu20046_qemu" {
  vm_name           = "${var.vm_name}.qcow2"
  headless          = true
  iso_url           = var.iso_url
  iso_checksum      = var.iso_checksum
  http_directory    = "http"
  cpus              = var.cpus
  memory            = var.memory
  disk_size         = "${var.disk_size}"
  accelerator       = "kvm"
  ssh_username      = var.username
  ssh_password      = var.password
  ssh_timeout       = "1h"
  ip_wait_timeout = "10m"
  shutdown_command  = "echo ${var.password} | sudo -S shutdown -P now"
  format            = "qcow2"
  boot_wait         = "120s"
  boot_command      = [
    "<esc><wait>",
    "<esc><wait>",
    "<enter><wait>",
    "/install/vmlinuz<wait>",
    " initrd=/install/initrd.gz",
    " auto-install/enable=true",
    " debconf/priority=critical",
    " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<wait>",
    " hostname=${var.vm_name}",
    " -- <wait>",
    "<enter><wait>"
  ]
}

build {
  sources = [
    "sources.qemu.ubuntu20046_qemu"
  ]
  provisioner "shell" {
    inline = [
      "echo ${var.password} | sudo -S bash -c \"echo '${var.username} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/99_vm\"",
      "echo ${var.password} | sudo -S sudo chmod 440 /etc/sudoers.d/99_vm",
      "sudo bash -c 'cat << EOF > /etc/netplan/01-netcfg.yaml",
      "network:",
      "  version: 2",
      "  renderer: networkd",
      "  ethernets:",
      "    id0:",
      "      match:",
      "        name: e*",
      "      dhcp4: yes",
      "EOF'",
      "sudo apt-get install -y git curl",
      "curl -sSL https://raw.githubusercontent.com/nsg-ethz/p4-utils/update-p4-tools/install-tools/install-p4-dev-ubuntu20.sh | bash"
    ]
  }
}

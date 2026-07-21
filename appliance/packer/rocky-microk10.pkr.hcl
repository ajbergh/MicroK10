packer {
  required_plugins {
    vmware = {
      version = ">= 2.1.3"
      source  = "github.com/vmware/vmware"
    }
  }
}

variable "rocky_version" { default = "9.8" }
variable "iso_url" { type = string }
variable "iso_checksum" { type = string }
variable "ssh_public_key" { type = string }
variable "ssh_private_key_file" { type = string }
variable "guest_os_type" { default = "rhel9-64" }
variable "cpus" { default = 8 }
variable "memory_mb" { default = 16384 }
variable "disk_mb" { default = 153600 }

source "vmware-iso" "microk10" {
  vm_name       = "MicroK10-${var.rocky_version}"
  guest_os_type = var.guest_os_type
  iso_url       = var.iso_url
  iso_checksum  = var.iso_checksum
  headless      = true
  cpus          = var.cpus
  memory        = var.memory_mb
  disk_size     = var.disk_mb
  disk_type_id  = "0"
  network       = "nat"
  http_content = {
    "/rocky.ks" = templatefile("${path.root}/http/rocky.ks.pkrtpl.hcl", { ssh_public_key = var.ssh_public_key })
  }
  boot_wait            = "10s"
  boot_command         = ["<up><wait><tab><wait> inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/rocky.ks<enter>"]
  ssh_username         = "microk10"
  ssh_private_key_file = var.ssh_private_key_file
  ssh_timeout          = "30m"
  shutdown_command     = "sudo /opt/microk10/appliance/packer/scripts/finalize-image.sh"
  shutdown_timeout     = "10m"
  format               = "ova"
  skip_compaction      = false
}

build {
  sources = ["source.vmware-iso.microk10"]

  provisioner "shell" {
    inline = [
      "sudo rm -rf /opt/microk10",
      "sudo install -d -o microk10 -g microk10 /opt/microk10"
    ]
  }

  provisioner "file" {
    source      = "./"
    destination = "/opt/microk10/"
  }

  provisioner "shell" {
    script = "appliance/packer/scripts/provision.sh"
    environment_vars = ["ROCKY_VERSION=${var.rocky_version}"]
  }
}

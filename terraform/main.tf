terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox" // Or your preferred community provider
      version = "3.0.1-rc9"       // Use the latest compatible version
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "nfs-server" {
  target_node = var.proxmox_node
  vmid        = 201
  name        = "nfs-server-node01"
  desc        = "NFS Server Node"
  clone       = "tpl-almalinux-9"
  full_clone  = true
  onboot      = true
  agent       = 1
  os_type     = "cloud-init"
  bios        = "ovmf"
  boot        = "order=scsi0"
  scsihw      = "virtio-scsi-single"
  vm_state    = "running"

  # Resource limits
  cores    = 4
  sockets  = 2
  cpu_type = "host"
  memory   = 8192

  # Cloud-Init configuration
  cicustom   = "vendor=local:snippets/qemu-guest-agent.yml"
  ciupgrade  = true
  nameserver = var.cinit_conf_nameservers
  ipconfig0  = "ip=192.168.0.201/24,gw=${var.cinit_conf_gateway},ip6=dhcp"
  skip_ipv6  = true
  ciuser     = var.ssh_default_user
  cipassword = var.ssh_default_user_password
  sshkeys    = var.ssh_public_key

  serial {
    id = "0"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-zfs"
          size    = "50G"
          format  = "raw"
        }
      }
      scsi1 {
        disk {
          storage = "nvme_vm_storage"
          size    = "2048G"
          format  = "raw"
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = "local-zfs"
        }
      }
    }
  }

  network {
    id = 0
    bridge = "vmbr0"
    model  = "virtio"
  }
}

resource "proxmox_vm_qemu" "k8s_control_plane" {
  target_node = var.proxmox_node
  vmid        = 210
  name        = "k8s-control-plane"
  desc        = "Kubernetes Control Plane Node"
  clone       = var.vm_template_name
  full_clone  = true
  onboot      = true
  agent       = 1
  os_type     = "cloud-init"
  bios        = "ovmf"
  boot        = "order=scsi0"
  scsihw      = "virtio-scsi-single"
  vm_state    = "running"

  # Resource limits
  cores    = 2
  sockets  = 1
  cpu_type = "host"
  memory   = 8192

  # Cloud-Init configuration
  cicustom   = "vendor=local:snippets/qemu-guest-agent.yml"
  ciupgrade  = true
  nameserver = var.cinit_conf_nameservers
  ipconfig0  = "ip=192.168.0.210/24,gw=${var.cinit_conf_gateway},ip6=dhcp"
  skip_ipv6  = true
  ciuser     = var.ssh_default_user
  cipassword = var.ssh_default_user_password
  sshkeys    = var.ssh_public_key

  serial {
    id = "0"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-zfs"
          size    = "50G"
          format  = "raw"
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = "local-zfs"
        }
      }
    }
  }

  network {
    id = 0
    bridge = "vmbr0"
    model  = "virtio"
  }
}

// --- Kubernetes CPU Worker Nodes ---
resource "proxmox_vm_qemu" "k8s_cpu_worker" {
  count       = var.cpu_worker_count
  target_node = var.proxmox_node
  vmid        = 211 + count.index
  name        = "k8s-cpu-worker0${count.index + 1}"
  desc        = "Kubernetes CPU Worker Node"
  clone       = var.vm_template_name
  full_clone  = true
  onboot      = true
  agent       = 1
  os_type     = "cloud-init"
  bios        = "ovmf"
  boot        = "order=scsi0"
  scsihw      = "virtio-scsi-single"
  vm_state    = "running"

  # Resource limits
  cores    = 4
  sockets  = 2
  cpu_type = "host"
  memory   = 16384

  # Cloud-Init configuration
  cicustom   = "vendor=local:snippets/qemu-guest-agent.yml"
  ciupgrade  = true
  nameserver = var.cinit_conf_nameservers
  ipconfig0  = "ip=192.168.0.21${1 + count.index}/24,gw=${var.cinit_conf_gateway},ip6=dhcp"
  skip_ipv6  = true
  ciuser     = var.ssh_default_user
  cipassword = var.ssh_default_user_password
  sshkeys    = var.ssh_public_key

  serial {
    id = "0"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-zfs"
          size    = "50G"
          format  = "raw"
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = "local-zfs"
        }
      }
    }
  }

  network {
    id = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  depends_on = [proxmox_vm_qemu.k8s_control_plane]
}

// --- Kubernetes GPU Worker Nodes ---
resource "proxmox_vm_qemu" "k8s_gpu_worker" {
  count       = var.gpu_worker_count
  target_node = var.proxmox_node
  vmid        = 211 + var.cpu_worker_count + count.index
  name        = "k8s-gpu-worker0${count.index + var.cpu_worker_count + 1}"
  desc        = "Kubernetes GPU Worker Node"
  clone       = "tpl-ubuntu-2202"
  full_clone  = true
  onboot      = true
  agent       = 1
  os_type     = "cloud-init"
  bios        = "ovmf"
  boot        = "order=scsi0"
  scsihw      = "virtio-scsi-single"
  vm_state    = "running"

  # Resource limits
  cores    = 6
  sockets  = 2
  cpu_type = "host"
  memory   = 32768

  # Cloud-Init configuration
  cicustom   = "vendor=local:snippets/qemu-guest-agent.yml"
  ciupgrade  = true
  nameserver = var.cinit_conf_nameservers
  ipconfig0  = "ip=192.168.0.21${var.cpu_worker_count + 1 + count.index}/24,gw=${var.cinit_conf_gateway},ip6=dhcp"
  skip_ipv6  = true
  ciuser     = var.ssh_default_user
  cipassword = var.ssh_default_user_password
  sshkeys    = var.ssh_public_key

  serial {
    id = "0"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-zfs"
          size    = "50G"
          format  = "raw"
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = "local-zfs"
        }
      }
    }
  }

  network {
    id = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  depends_on = [proxmox_vm_qemu.k8s_control_plane]
}
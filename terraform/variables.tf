variable "proxmox_api_url" {
  type        = string
  description = "URL for the Proxmox API (e.g., https://192.168.0.200:8006/api2/json)"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Proxmox API Token ID (e.g., terraform-user@pve!mytoken)"
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Proxmox API Token Secret"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  default     = "pve"
  description = "The Proxmox node to deploy VMs on."
}

variable "vm_template_name" {
  type        = string
  description = "Name of the Proxmox VM template to clone (e.g., almalinux10-cloudinit-template)"
}

variable "ssh_public_key" {
  type        = string
  description = "Your public SSH key for VM access."
}

variable "ssh_default_user" {
  description = "Default SSH user for the VMs."
  type        = string
  default     = "gizzmo"
}

variable "ssh_default_user_password" {
  description = "Default SSH user password for the VMs."
  type        = string
  default     = "gizzmo1234"
  sensitive   = true
}

variable "cinit_conf_nameservers" {
  description = "Nameservers for Cloud-Init configuration."
  type        = string
  default     = "192.168.0.3 1.1.1.1 8.8.8.8"
}

variable "cinit_conf_gateway" {
  description = "Gateway for Cloud-Init configuration."
  type        = string
  default     = "192.168.0.1"
}

variable "cpu_worker_count" {
  description = "Number of CPU worker nodes."
  type        = number
  default     = 1
}

variable "gpu_worker_count" {
  description = "Number of GPU worker nodes."
  type        = number
  default     = 1
}
# bastion_ip_address = "${module.infrastructure.bastion_public_ip}"
# private_ssh_key    = "${var.private_ssh_key}"
# ssh_username       = "${var.ssh_user}"
# storage_hostname   = "${module.infrastructure.storage_hostname}"
# storage_private_ip = "${module.infrastructure.storage_private_ip}"
# storage            = "${var.storage}"

variable "bastion_ip_address" {}
variable "bastion_ssh_user" {}
variable "bastion_ssh_password" {}
variable "bastion_ssh_private_key" {}

variable "storage_private_ip" {
  type = "list"
}
variable "master_private_ip" {
  type = "list"
}
variable "storage" {
  type = "map"
}
variable "master" {
  type = "map"
}

variable "dependson" {
  type = "list"
  default = []
}

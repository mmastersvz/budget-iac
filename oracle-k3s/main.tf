module "network" {
  source = "./modules/network"

  compartment_ocid = var.compartment_ocid
  cidr_block       = "10.0.0.0/16"
  subnet_cidr      = "10.0.1.0/24"
  allowed_cidr     = var.allowed_cidr
}

module "compute" {
  source = "./modules/compute"

  compartment_ocid     = var.compartment_ocid
  subnet_id            = module.network.subnet_id
  ssh_public_key       = var.ssh_public_key
  ssh_private_key_path = var.ssh_private_key_path
  tenancy_ocid         = var.tenancy_ocid
}

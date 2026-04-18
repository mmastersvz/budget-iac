variable "compartment_ocid" {
  description = "OCID of the OCI compartment"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID from the network module"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key to authorize on the instance"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key for kubeconfig retrieval"
  type        = string
}

variable "tenancy_ocid" {
  description = "OCID of the OCI tenancy (used to query availability domains)"
  type        = string
}

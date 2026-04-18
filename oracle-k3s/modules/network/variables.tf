variable "compartment_ocid" {
  description = "OCID of the OCI compartment"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VCN"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "allowed_cidr" {
  description = "CIDR allowed to reach SSH (22) and Kubernetes API (6443)"
  type        = string
}

variable "tenancy_ocid" {
  description = "OCID of your OCI tenancy"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID of the compartment to deploy into (use tenancy_ocid for root)"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the OCI user for API authentication"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the OCI API key pair"
  type        = string
}

variable "private_key_path" {
  description = "Path to the OCI API private key PEM file"
  type        = string
}

variable "region" {
  description = "OCI region (e.g. us-ashburn-1, ap-sydney-1)"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key to authorize on the k3s node"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key used to retrieve kubeconfig after provisioning"
  type        = string
}

variable "alert_email" {
  description = "Email address to notify if any OCI charges are detected"
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

variable "allowed_cidr" {
  description = "Your IP in CIDR notation — restricts SSH and K8s API access (e.g. 1.2.3.4/32)"
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_cidr, 0))
    error_message = "allowed_cidr must be a valid CIDR block (e.g. 1.2.3.4/32)."
  }
}

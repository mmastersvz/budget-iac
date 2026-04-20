terraform {
  required_version = ">= 1.6"

  # NOTE: OCI Object Storage S3 API is incompatible with Terraform 1.8+ (chunked encoding).
  # State is stored locally. Back up terraform.tfstate manually or use Terraform Cloud free tier.

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.10"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

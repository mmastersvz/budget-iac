terraform {
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

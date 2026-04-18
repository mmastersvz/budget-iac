# Root module plan validation — runs without real OCI credentials
# Run: terraform test

mock_provider "oci" {
  mock_data "oci_identity_availability_domains" {
    defaults = {
      availability_domains = [{ name = "US-ASHBURN-AD-1", id = "fake-ad-1" }]
    }
  }

  mock_data "oci_core_images" {
    defaults = {
      images = [{ id = "ocid1.image.oc1..fake" }]
    }
  }
}

mock_provider "null" {}

variables {
  tenancy_ocid         = "ocid1.tenancy.oc1..fake"
  compartment_ocid     = "ocid1.compartment.oc1..fake"
  user_ocid            = "ocid1.user.oc1..fake"
  fingerprint          = "00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff"
  private_key_path     = "/tmp/fake_oci.pem"
  region               = "us-ashburn-1"
  ssh_public_key       = "ssh-rsa AAAAB3NzaC1yc2E test@test"
  ssh_private_key_path = "/tmp/fake_ssh"
  allowed_cidr         = "1.2.3.4/32"
}

run "plan_succeeds" {
  command = plan
}

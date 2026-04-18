# Compute module tests
# Run from repo root: terraform test -test-directory=modules/compute/tests

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
  compartment_ocid     = "ocid1.compartment.oc1..fake"
  subnet_id            = "ocid1.subnet.oc1..fake"
  ssh_public_key       = "ssh-rsa AAAAB3NzaC1yc2E test@test"
  ssh_private_key_path = "/tmp/fake_ssh"
  tenancy_ocid         = "ocid1.tenancy.oc1..fake"
}

run "plan_succeeds" {
  command = plan
}

run "uses_always_free_max_ocpus" {
  command = plan

  assert {
    condition     = oci_core_instance.this.shape_config[0].ocpus == 4
    error_message = "Must use 4 OCPUs — the Always Free maximum for VM.Standard.A1.Flex"
  }
}

run "uses_always_free_max_memory" {
  command = plan

  assert {
    condition     = oci_core_instance.this.shape_config[0].memory_in_gbs == 24
    error_message = "Must use 24 GB RAM — the Always Free maximum for VM.Standard.A1.Flex"
  }
}

run "boot_volume_within_free_tier" {
  command = plan

  assert {
    condition     = oci_core_instance.this.source_details[0].boot_volume_size_in_gbs == 100
    error_message = "Boot volume should be 100 GB (within the 200 GB Always Free total)"
  }
}

run "uses_arm_shape" {
  command = plan

  assert {
    condition     = oci_core_instance.this.shape == "VM.Standard.A1.Flex"
    error_message = "Must use VM.Standard.A1.Flex — the Always Free ARM shape"
  }
}

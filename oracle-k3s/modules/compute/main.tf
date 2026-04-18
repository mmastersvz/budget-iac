data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "oracle_linux" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = "VM.Standard.A1.Flex"
}

resource "oci_core_instance" "this" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name

  shape = "VM.Standard.A1.Flex"

  # Always Free maximum: 4 OCPUs and 24 GB RAM total across all A1 instances
  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(file("${path.module}/cloud-init.yaml"))
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.oracle_linux.images[0].id
    boot_volume_size_in_gbs = 100
  }

  display_name = "k3s-node"

  lifecycle {
    precondition {
      condition     = self.shape == "VM.Standard.A1.Flex"
      error_message = "Shape must be VM.Standard.A1.Flex to stay on Always Free tier."
    }
    precondition {
      condition     = self.shape_config[0].ocpus <= 4
      error_message = "OCPUs must not exceed 4 — the Always Free limit for VM.Standard.A1.Flex."
    }
    precondition {
      condition     = self.shape_config[0].memory_in_gbs <= 24
      error_message = "Memory must not exceed 24 GB — the Always Free limit for VM.Standard.A1.Flex."
    }
    precondition {
      condition     = self.source_details[0].boot_volume_size_in_gbs <= 200
      error_message = "Boot volume must not exceed 200 GB — the Always Free block storage limit."
    }
  }
}

# Wait for k3s to be ready then fetch kubeconfig with the public IP patched in
resource "null_resource" "fetch_kubeconfig" {
  depends_on = [oci_core_instance.this]

  triggers = {
    instance_id = oci_core_instance.this.id
  }

  provisioner "remote-exec" {
    connection {
      host        = oci_core_instance.this.public_ip
      user        = "opc"
      private_key = file(var.ssh_private_key_path)
    }
    inline = [
      "until sudo k3s kubectl get nodes --no-headers 2>/dev/null | grep -q Ready; do echo 'Waiting for k3s...'; sleep 15; done"
    ]
  }

  provisioner "local-exec" {
    command = <<-EOT
      scp -o StrictHostKeyChecking=no -i "${var.ssh_private_key_path}" \
        opc@${oci_core_instance.this.public_ip}:/home/opc/.kube/config \
        ${path.root}/kubeconfig
      sed -i 's|server: https://127.0.0.1:6443|server: https://${oci_core_instance.this.public_ip}:6443|g' \
        ${path.root}/kubeconfig
    EOT
  }
}

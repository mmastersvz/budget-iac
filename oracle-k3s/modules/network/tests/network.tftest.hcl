# Network module tests
# Run from repo root: terraform test -test-directory=modules/network/tests

mock_provider "oci" {}

variables {
  compartment_ocid = "ocid1.compartment.oc1..fake"
  cidr_block       = "10.0.0.0/16"
  subnet_cidr      = "10.0.1.0/24"
  allowed_cidr     = "1.2.3.4/32"
}

run "plan_succeeds" {
  command = plan
}

run "ssh_restricted_to_allowed_cidr" {
  command = plan

  assert {
    condition = alltrue([
      for rule in oci_core_security_list.this.ingress_security_rules :
      rule.source == var.allowed_cidr
      if length(rule.tcp_options) > 0 && rule.tcp_options[0].min == 22
    ])
    error_message = "SSH port 22 must only be accessible from allowed_cidr, not 0.0.0.0/0"
  }
}

run "k8s_api_restricted_to_allowed_cidr" {
  command = plan

  assert {
    condition = alltrue([
      for rule in oci_core_security_list.this.ingress_security_rules :
      rule.source == var.allowed_cidr
      if length(rule.tcp_options) > 0 && rule.tcp_options[0].min == 6443
    ])
    error_message = "K8s API port 6443 must only be accessible from allowed_cidr, not 0.0.0.0/0"
  }
}

run "http_open_to_all" {
  command = plan

  assert {
    condition = anytrue([
      for rule in oci_core_security_list.this.ingress_security_rules :
      rule.source == "0.0.0.0/0"
      if length(rule.tcp_options) > 0 && rule.tcp_options[0].min == 80
    ])
    error_message = "HTTP port 80 should be open to 0.0.0.0/0 for workloads"
  }
}

run "subnet_assigns_public_ips" {
  command = plan

  assert {
    condition     = oci_core_subnet.this.prohibit_public_ip_on_vnic == false
    error_message = "Subnet must allow public IP assignment"
  }
}

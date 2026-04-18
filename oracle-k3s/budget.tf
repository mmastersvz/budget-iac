# Fires an email alert if any charge appears — all resources should be $0
resource "oci_budget_budget" "free_tier_guard" {
  compartment_id = var.tenancy_ocid
  amount         = 1
  reset_period   = "MONTHLY"
  display_name   = "always-free-guard"
  description    = "Alerts on any spend — all resources should be Always Free"
  target_type    = "COMPARTMENT"
  targets        = [var.compartment_ocid]
}

resource "oci_budget_alert_rule" "any_spend" {
  budget_id      = oci_budget_budget.free_tier_guard.id
  threshold      = 0.01
  threshold_type = "ABSOLUTE"
  type           = "ACTUAL"
  display_name   = "zero-spend-alert"
  recipients     = var.alert_email
  message        = "OCI charges detected on always-free account — check for non-free resources immediately."
}

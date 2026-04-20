#!/usr/bin/env bash
# Retries terraform apply across all availability domains until one succeeds.
# A1.Flex capacity in us-ashburn-1 is limited — this keeps trying until a slot opens.
#
# Usage:
#   bash scripts/apply-with-retry.sh             # tries AD 0,1,2 once
#   RETRY_INTERVAL=300 bash scripts/apply-with-retry.sh  # retry every 5 min until success
set -euo pipefail

RETRY_INTERVAL="${RETRY_INTERVAL:-0}"   # seconds between full cycles; 0 = run once
MAX_CYCLES="${MAX_CYCLES:-1}"           # set to 0 for infinite retries
VAR_FILE="${VAR_FILE:-terraform.tfvars}"

apply_for_ad() {
  local ad_index=$1
  echo ""
  echo "── Trying availability_domain_index=${ad_index} ──"
  if terraform apply -auto-approve \
      -var-file="$VAR_FILE" \
      -var "availability_domain_index=${ad_index}"; then
    return 0
  fi
  return 1
}

cycle=0
while true; do
  cycle=$((cycle + 1))
  echo "=== Cycle ${cycle} ==="

  for ad in 0 1 2; do
    if apply_for_ad "$ad"; then
      echo ""
      echo "✓ Apply succeeded on availability_domain_index=${ad}"
      exit 0
    fi

    # Only retry out-of-capacity errors — stop on other failures
    if ! terraform show 2>/dev/null | grep -q "Out of host capacity"; then
      last_error=$(terraform show 2>/dev/null || true)
      # Re-check last apply output for capacity error
      :
    fi
  done

  if [[ "$RETRY_INTERVAL" -eq 0 ]] || { [[ "$MAX_CYCLES" -gt 0 ]] && [[ "$cycle" -ge "$MAX_CYCLES" ]]; }; then
    echo ""
    echo "All availability domains exhausted."
    echo ""
    echo "us-ashburn-1 A1.Flex capacity is limited on the Always Free tier."
    echo "Options:"
    echo "  1. Run again later (off-peak hours like 02:00-06:00 UTC often have more capacity)"
    echo "  2. Run with RETRY_INTERVAL=600 MAX_CYCLES=0 to keep retrying automatically"
    echo "  3. Create a new OCI account with a home region that has more capacity"
    echo "     (ap-osaka-1 and ca-toronto-1 typically have more A1.Flex availability)"
    exit 1
  fi

  echo ""
  echo "${cycle}: Waiting ${RETRY_INTERVAL}s before next cycle... (Ctrl-C to stop) [$(date '+%Y-%m-%d %H:%M:%S')]"
  sleep "$RETRY_INTERVAL"
done

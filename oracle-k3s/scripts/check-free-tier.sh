#!/usr/bin/env bash
# Audits running OCI resources against Always Free limits.
# Requires: oci cli configured, python3
# Usage: ./scripts/check-free-tier.sh <compartment_ocid>
set -euo pipefail

COMPARTMENT_OCID="${1:-}"
if [[ -z "$COMPARTMENT_OCID" ]]; then
  echo "Usage: $0 <compartment_ocid>" >&2
  exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

pass() { echo -e "  ${GREEN}✓${RESET} $*"; }
warn() { echo -e "  ${YELLOW}⚠${RESET} $*"; }
fail() { echo -e "  ${RED}✗${RESET} $*"; FAILED=1; }

FAILED=0

echo ""
echo "=== OCI Always Free tier audit ==="
echo "Compartment: $COMPARTMENT_OCID"
echo ""

# ---------------------------------------------------------------------------
# Compute instances
# ---------------------------------------------------------------------------
echo "--- Compute instances ---"

INSTANCES=$(oci compute instance list \
  --compartment-id "$COMPARTMENT_OCID" \
  --lifecycle-state RUNNING \
  --output json 2>/dev/null)

INSTANCE_COUNT=$(echo "$INSTANCES" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['data']))")

if [[ "$INSTANCE_COUNT" -eq 0 ]]; then
  warn "No running instances found"
else
  echo "$INSTANCES" | python3 - <<'EOF'
import sys, json

FREE_SHAPES = {"VM.Standard.A1.Flex", "VM.Standard.E2.1.Micro"}
A1_MAX_OCPUS = 4
A1_MAX_MEM_GB = 24
E2_MAX_INSTANCES = 2

data = json.load(sys.stdin)["data"]
total_a1_ocpus = 0
total_a1_mem = 0
e2_count = 0
failed = False

for inst in data:
    name = inst.get("display-name", inst["id"])
    shape = inst.get("shape", "")
    cfg = inst.get("shape-config", {})
    ocpus = cfg.get("ocpus", 0)
    mem = cfg.get("memory-in-gbs", 0)

    if shape == "VM.Standard.A1.Flex":
        total_a1_ocpus += ocpus
        total_a1_mem += mem
        print(f"  \033[0;32m✓\033[0m {name}: {shape} ({ocpus} OCPU / {mem} GB)")
    elif shape == "VM.Standard.E2.1.Micro":
        e2_count += 1
        print(f"  \033[0;32m✓\033[0m {name}: {shape} (Always Free)")
    else:
        print(f"  \033[0;31m✗\033[0m {name}: {shape} — NOT an Always Free shape, will incur charges!")
        failed = True

print()
# Check A1 totals
if total_a1_ocpus > A1_MAX_OCPUS:
    print(f"  \033[0;31m✗\033[0m A1.Flex total: {total_a1_ocpus} OCPU / {total_a1_mem} GB — OVER limit ({A1_MAX_OCPUS} OCPU / {A1_MAX_MEM_GB} GB)")
    failed = True
elif total_a1_ocpus > 0:
    print(f"  \033[0;32m✓\033[0m A1.Flex total: {total_a1_ocpus}/{A1_MAX_OCPUS} OCPU, {total_a1_mem}/{A1_MAX_MEM_GB} GB")

if e2_count > E2_MAX_INSTANCES:
    print(f"  \033[0;31m✗\033[0m E2.1.Micro count: {e2_count} — OVER limit ({E2_MAX_INSTANCES})")
    failed = True
EOF
fi

# ---------------------------------------------------------------------------
# Boot volumes
# ---------------------------------------------------------------------------
echo ""
echo "--- Boot volumes ---"

BOOT_VOLS=$(oci bv boot-volume list \
  --compartment-id "$COMPARTMENT_OCID" \
  --output json 2>/dev/null)

echo "$BOOT_VOLS" | python3 - <<'EOF'
import sys, json

FREE_MAX_GB = 200
data = json.load(sys.stdin)["data"]
total_gb = 0

for vol in data:
    name = vol.get("display-name", vol["id"])
    size = vol.get("size-in-gbs", 0)
    total_gb += size
    print(f"  {'✓' if size <= FREE_MAX_GB else '⚠'} {name}: {size} GB")

print()
color = "\033[0;32m" if total_gb <= FREE_MAX_GB else "\033[0;31m"
reset = "\033[0m"
mark = "✓" if total_gb <= FREE_MAX_GB else "✗"
print(f"  {color}{mark}{reset} Total block storage: {total_gb}/{FREE_MAX_GB} GB")
if total_gb > FREE_MAX_GB:
    print(f"  \033[0;31m✗\033[0m OVER the 200 GB Always Free limit — will incur charges!")
EOF

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "--- Budget alerts ---"
BUDGETS=$(oci budgets budget list \
  --compartment-id "$COMPARTMENT_OCID" \
  --output json 2>/dev/null)

BUDGET_COUNT=$(echo "$BUDGETS" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['data']))")
if [[ "$BUDGET_COUNT" -gt 0 ]]; then
  pass "$BUDGET_COUNT budget alert(s) configured"
else
  warn "No budget alerts configured — run terraform apply to create one"
fi

echo ""
if [[ "$FAILED" -eq 0 ]]; then
  echo -e "${GREEN}All checks passed — resources appear to be within Always Free limits.${RESET}"
else
  echo -e "${RED}One or more checks failed — review the output above.${RESET}"
  exit 1
fi
echo ""

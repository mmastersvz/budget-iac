# k3s on Oracle Cloud — Always Free

Single-node [k3s](https://k3s.io) Kubernetes cluster on Oracle Cloud Infrastructure using only **Always Free** resources. No credit card charges.

## What gets created

| Resource | Spec | Cost |
|---|---|---|
| VM.Standard.A1.Flex (ARM) | 4 OCPU / 24 GB RAM | Free |
| Boot volume | 100 GB | Free |
| VCN + subnet + internet gateway | — | Free |

Oracle's Always Free tier includes 4 ARM OCPUs and 24 GB RAM total — this config uses all of it for a single beefy node.

## Prerequisites

- Oracle Cloud account ([sign up](https://www.oracle.com/cloud/free/))
- Terraform >= 1.6
- OCI CLI configured **or** API key files on disk
- SSH key pair

## Setup

### 1. OCI API key

In OCI Console → Profile (top right) → **API Keys** → Add API Key. Download the private key and note the fingerprint.

### 2. Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
tenancy_ocid     = "ocid1.tenancy.oc1..aaaa..."
user_ocid        = "ocid1.user.oc1..aaaa..."
fingerprint      = "xx:xx:xx:xx:..."
private_key_path = "~/.oci/oci_api_key.pem"
region           = "us-ashburn-1"          # pick your closest region

compartment_ocid     = "ocid1.tenancy.oc1..aaaa..."  # root compartment = tenancy OCID
ssh_public_key       = "ssh-rsa AAAAB3..."
ssh_private_key_path = "~/.ssh/id_rsa"

# Your IP — run: curl -s ifconfig.me
allowed_cidr = "1.2.3.4/32"
```

### 3. Find your region

OCI region identifiers: `us-ashburn-1`, `us-phoenix-1`, `eu-frankfurt-1`, `ap-sydney-1`, `ap-tokyo-1`, etc. Pick one close to you — the free tier is available in all home regions.

## Deploy

```bash
terraform init
terraform plan
terraform apply
```

After `apply` completes (~5–10 minutes for cloud-init + k3s to start), Terraform will:
1. SSH into the node and wait for k3s to report `Ready`
2. Download the kubeconfig to `./kubeconfig` with the public IP patched in

## Access the cluster

```bash
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```

Or use the output directly:

```bash
$(terraform output -raw kubectl_command)
```

## Staying free

Three layers protect against accidental charges:

**1. OCI Budget alert** (Terraform-managed) — sends email to `alert_email` if actual spend exceeds $0.01 in any month. Created automatically by `terraform apply`.

**2. Lifecycle preconditions** — `terraform apply` will hard-fail if the compute instance shape, OCPU count, memory, or boot volume size would exceed Always Free limits. Catches config drift before it hits OCI.

**3. Audit script** — check any time with OCI CLI:
```bash
./scripts/check-free-tier.sh <compartment_ocid>
```
Checks running instance shapes, total A1.Flex OCPU/memory usage, boot volume total, and whether budget alerts are configured. Exits non-zero if anything is out of range.

Always Free limits this config stays within:
| Resource | Used | Limit |
|---|---|---|
| A1.Flex OCPUs | 4 | 4 |
| A1.Flex RAM | 24 GB | 24 GB |
| Boot volume | 100 GB | 200 GB total |

## Destroy

```bash
terraform destroy
```

This removes all resources including the budget alert.

## Running tests

Tests use Terraform's built-in test framework (>= 1.6) with mocked providers — no real OCI account needed.

```bash
# Full root module plan
terraform test

# Network module assertions
terraform test -test-directory=modules/network/tests

# Compute module assertions
terraform test -test-directory=modules/compute/tests
```

## Architecture

```
Internet
    │
    ▼
Internet Gateway
    │
VCN (10.0.0.0/16)
    │
Public Subnet (10.0.1.0/24)
    │
VM.Standard.A1.Flex
  ├── 4 OCPU / 24 GB RAM
  ├── 100 GB boot volume
  └── k3s (single-node)
```

Security list rules:
- Port 22, 6443 → your IP only (`allowed_cidr`)
- Port 80, 443 → open (for workloads)
- All egress → open

## Notes

- **firewalld is disabled** on the instance — OCI security lists handle ingress filtering
- kubeconfig is saved to `./kubeconfig` and excluded from git
- The `null_resource` that fetches kubeconfig re-runs if the instance is replaced
- To add worker nodes: create additional A1.Flex instances and join them with the k3s token at `/var/lib/rancher/k3s/server/node-token`

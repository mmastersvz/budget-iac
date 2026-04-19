# budget-iac

Zero-cost infrastructure on [Oracle Cloud](https://www.oracle.com/cloud/) — [k3s](https://k3s.io) cluster with [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) GitOps. Uses only [Always Free](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm) resources.

## Structure

```
budget-iac/
├── oracle-k3s/          Terraform — provisions k3s node on OCI Always Free tier
├── bootstrap/
│   ├── argocd/          Scripts — installs ArgoCD and initialises GitOps
│   └── state/           Scripts — provisions OCI Object Storage bucket for tfstate
└── .tool-versions       asdf — terraform 1.14.8, kubectl 1.35.4
```

## End-to-end flow

```
1. oracle-k3s/          terraform apply        → k3s node + kubeconfig
2. bootstrap/state/     init-backend.sh        → remote tfstate (optional)
3. bootstrap/argocd/    make scaffold + bootstrap → ArgoCD + 5 hello-world apps
```

See each directory's README for detailed steps. Full walkthrough: [bootstrap/ARGOCD-SETUP.md](bootstrap/ARGOCD-SETUP.md).

## Always Free tier used

| Resource | Spec | Cost |
|---|---|---|
| [VM.Standard.A1.Flex](https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm) (ARM) | 4 OCPU / 24 GB RAM | Free |
| Boot volume | 100 GB | Free |
| [VCN](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/VCNs_and_Subnets.htm) + networking | — | Free |
| [OCI Budget alert](https://docs.oracle.com/en-us/iaas/Content/Billing/Concepts/budgetsoverview.htm) | 1 per compartment | Free |
| [OCI Object Storage](https://docs.oracle.com/en-us/iaas/Content/Object/Concepts/objectstorageoverview.htm) | < 1 MB state file | Free (20 GB limit) |

See [OCI pricing](https://www.oracle.com/cloud/price-list.html) for full details.

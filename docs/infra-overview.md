# Liv Golf Infrastructure Overview

This one-pager captures the shared infrastructure agreements for the Liv Golf Google Cloud footprint. The intent is to keep all
teams aligned on naming conventions, baseline networking, data movement, and the controls we rely on for parallel workloads and
queue management.

## Naming convention (applies to every resource)

* Pattern: `livgolf-{component_type}-{purpose}-{instance_number}-{environment}`
* Rules: lowercase only, hyphen separators, no special characters, make every token readable, keep names concise but descriptive.
* Component type codes:

| Domain | Codes |
| --- | --- |
| Compute | `vm`, `cont`, `k8s`, `sl`, `dataproc`, `run`, `df` |
| Storage & Data Lake | `gcs`, `disk`, `filestore`, `dl` |
| Databases | `sql`, `bq`, `nosql`, `cache` |
| Networking | `vpc`, `snet`, `fw`, `lb`, `rt`, `vpn` |
| Ingestion & Orchestration | `pubsub`, `etl`, `wf` |
| Monitoring | `log`, `dash`, `alert` |
| Security | `iam`, `kms`, `secret` |
| Edge & Misc | `api`, `dns`, `cdn`, `bck` |

The `scripts/bootstrap_state.sh` helper can now generate and validate names, so every Terraform backend bucket or future module
resource automatically adheres to the standard. See the README for usage examples.

## Infrastructure configuration & workloads

1. **State management / automation**: Terragrunt orchestrates the Terraform modules. The remote state bucket (component type
   `gcs`) is created via the `modules/gcs_backend` module, which enforces naming and lifecycle settings (versioning + retention).
2. **Compute tiers**: Modular expansion is expected through Cloud Run (`run`), GKE (`k8s`), Dataproc (`dataproc`), and VMs (`vm`).
   Each environment directory under `envs/` should supply Terragrunt inputs for the target module(s) and adhere to the naming
   pattern when instantiating resources.
3. **Data platforms**: BigQuery (`bq`) and Cloud SQL (`sql`) modules can be layered in later; keep datasets per environment and
   use the audit sheet to capture configuration (tier, region, retention).
4. **Observability**: Cloud Logging sinks (`log`), Monitoring dashboards (`dash`), and alerts (`alert`) follow the same naming
   rules. Compose module inputs so that dashboards map to the workload they monitor (e.g., `livgolf-dash-ops-01-prod`).

## Networking & security topology

* **Core VPCs**: Standardised naming `livgolf-vpc-shared-01-prod`, etc. Each VPC module should publish subnets (`snet`) with CIDR
  ranges captured in the audit sheet. Reuse Cloud Routers (`rt`) and VPN gateways (`vpn`) per edge site, referencing secrets for
  shared keys.
* **Load balancing & ingress**: Global HTTPS load balancers (`lb`) pair with Cloud Armor policies. Firewall rules (`fw`) must be
  grouped by intent (e.g., `fw-admin`, `fw-app`).
* **Identity & secrets**: IAM bindings use the `livgolf-iam-*` naming. Encrypt data with CMEK via Cloud KMS key rings (`kms`) and
  track secrets in Secret Manager entries (`secret`) that map one-to-one with consuming workloads.

## Org-wide VPC & IP strategy (staging focus)

The Google Cloud organisation owns the `10.64.0.0/10` RFC1918 block which is carved into sixteen `/14` project allocations to
support up to 16 projects. P1 (staging) maps to `10.64.0.0/14` and follows the compact per-region template below (first region:
`us-central1`).

| Resource | CIDR | Notes |
| --- | --- | --- |
| Workload subnet | `10.64.0.0/23` | Dual-stack subnet for GCE/Dataflow; IPv6 auto-assigned. |
| GKE Pods secondary | `10.66.0.0/21` | 2,048 pod IPs; add another /21 later if needed. |
| GKE Services secondary | `10.66.8.0/25` | 128 ClusterIPs; stamp more /25s as clusters grow. |
| Serverless VPC connector subnet | `10.70.0.0/27` | Shared by Cloud Run/Functions connectors; create extra /27s for isolation. |
| PSA range | `10.71.0.0/17` | Project-wide for Cloud SQL, Memorystore, etc.; allocate another range when exhausted. |

Apigee peering reserves `/22` + `/28` ranges beginning at `10.70.128.0/22`, though those resources are not yet automated. The
Terragrunt staging stack consumes the above ranges so subsequent modules (GKE, Cloud SQL, Cloud Run) can reference them without
guessing CIDRs.

## Parallelisation, orchestration, and batch windows

* **Data pipelines**: Dataflow (`df`) templates and Dataproc (`dataproc`) clusters should set worker counts explicitly and rely on
  autoscaling policies stored in Terraform variables. Concurrency-limited Cloud Run services can be declared with the
  `max_instance_count` attribute to prevent noisy neighbors.
* **Workflow coordination**: Cloud Composer or Workflows (`wf`) orchestrate DAGs that fan out work. Align task IDs with the
  resource names to simplify log discovery.
* **Infrastructure parallelism**: Terragrunt `run-all` with `--parallelism` enables concurrent module deployments as long as the
  resource graph is independent. Record any dependencies in `docs/resource_audit.csv` so operators know when to serialize runs.

## Queue management & ingestion

* **Pub/Sub** (`pubsub`) topics/subscriptions name their purpose (e.g., `livgolf-pubsub-scorecards-01-prod`). Capture retention,
  dead-letter policies, and push endpoints in the audit sheet.
* **APIs & ETL**: API Gateway entries (`api`) front the ingestion services, while Cloud Data Fusion/Dataflow ETL jobs (`etl`) move
  data into the landing buckets (`dl`). Each ETL job should write operational metrics to Logging with the same base name, allowing
  dashboards to auto-discover them.

## Auditing & Google Sheet hand-off

The repository includes `docs/resource_audit.csv`, which mirrors the columns requested for a Google Sheet (name, component type,
configuration notes, owner, state). Import it into Sheets/Looker Studio for live tracking and extend it as modules are added.

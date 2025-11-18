# Terraform / Terragrunt Bootstrap Skeleton

This repository provides a starting point for provisioning infrastructure on Google Cloud Platform using Terraform modules orchestrated by Terragrunt. The initial focus is on bootstrapping remote state resources (Google Cloud Storage bucket + prefix) so that additional infrastructure modules such as VPC, GKE, Cloud Run, and databases can be layered on incrementally.

## Repository layout

```
.
├── bootstrap/                # Terraform configuration that creates the remote state bucket
├── config/                   # Terragrunt configuration data (backend, project defaults, etc.)
├── envs/                     # Environment specific Terragrunt stacks (prod, staging, ...)
├── modules/                  # Reusable Terraform modules (GCS backend, networking, ...)
├── scripts/                  # Helper scripts (bootstrap automation, validation)
└── terragrunt.hcl            # Root Terragrunt configuration shared by all environments
```

## Prerequisites

* Terraform >= 1.5
* Terragrunt >= 0.50
* Google Cloud SDK (for authentication and optional bucket existence checks)
* A Google Cloud service account key JSON file with permissions to administer the target project (recommended roles: `roles/storage.admin`, `roles/resourcemanager.projectIamAdmin`).

Set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to the path of the JSON key before running any scripts.

## Bootstrapping remote state

1. Copy the sample backend configuration and update it with your desired values.

   ```bash
   cp config/backend.hcl.example config/backend.hcl
   $EDITOR config/backend.hcl
   ```

2. Execute the bootstrap script. It will:
   * Validate arguments and prerequisites.
   * Run the Terraform code under `bootstrap/` which ensures the backend bucket exists and is properly configured.
   * Persist the Terragrunt backend configuration (`config/backend.hcl`).

   ```bash
   scripts/bootstrap_state.sh \
     --project-id=my-gcp-project \
     --bucket-name=my-tf-state-bucket \
     --bucket-location=us \
     --default-region=us-central1
   ```

3. Once the bootstrap step has completed, you can run Terragrunt from an environment directory. For example, to target `envs/prod`:

   ```bash
   cd envs/prod
   terragrunt run-all plan
   ```

## Next steps

After the backend is configured you can incrementally add infrastructure modules (VPC, GKE, Cloud SQL, Cloud Run, etc.) under `modules/` and reference them from environment-specific `terragrunt.hcl` files inside `envs/`.

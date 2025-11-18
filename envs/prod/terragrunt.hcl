include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  environment = "prod"
}

terraform {
  source = "../../modules/placeholders/null"
}

inputs = {
  environment = local.environment
}

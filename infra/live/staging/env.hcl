locals {
  project_id     = get_env("PROJECT_ID")     # export via your deploy script
  region         = "us-central1"             # provider default region
  env_slug       = "staging"
  impersonate_sa = get_env("DEPLOY_SA_EMAIL")
}

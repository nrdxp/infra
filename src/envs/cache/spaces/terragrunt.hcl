locals {
  id  = get_env("AWS_ACCESS_KEY_ID")
  key = get_env("AWS_SECRET_ACCESS_KEY")
}
include "root" {
  path = find_in_parent_folders()
}

terraform {
  # See: https://github.com/gruntwork-io/terragrunt/issues/1675
  source = "${get_repo_root()}/src/modules/storage//."
}

inputs = {
  bucket     = "cache"
  region     = "sfo3"
  policy     = "${get_terragrunt_dir()}/policy.json"
  zone       = "nrd.sh"
  access_id  = local.id
  secret_key = local.key
}

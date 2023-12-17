include "root" {
  path = find_in_parent_folders()
}

terraform {
  # See: https://github.com/gruntwork-io/terragrunt/issues/1675
  source = "${get_repo_root()}/infra/modules/storage//."
}

inputs = {
  bucket    = "cache"
  region    = "sfo3"
  policy    = "${get_terragrunt_dir()}/policy.json"
  zone      = "nrd.sh"
}

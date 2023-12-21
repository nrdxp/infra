locals {
  endpoint = get_env("AWS_ENDPOINT_URL")
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    disable_bucket_update       = true

    bucket = "nrd-tf"

    endpoint = local.endpoint

    key            = "${split("envs/", path_relative_to_include())[1]}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

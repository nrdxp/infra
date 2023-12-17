provider "digitalocean" { }

resource "digitalocean_spaces_bucket" "cache" {
  name = "${var.bucket}.${data.cloudflare_zone.zone.name}"
  region = var.region
}

resource "digitalocean_spaces_bucket_policy" "cache" {
  region = digitalocean_spaces_bucket.cache.region
  bucket = digitalocean_spaces_bucket.cache.name
  policy = file(var.policy)
}

provider "cloudflare" {}

data "cloudflare_zone" "zone" {
  name = var.zone
}

resource "cloudflare_record" "cache" {
  zone_id = data.cloudflare_zone.zone.id
  name    = var.bucket
  value   = digitalocean_spaces_bucket.cache.endpoint
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_ruleset" "cache" {
  kind    = "zone"
  name    = "default"
  phase   = "http_request_cache_settings"
  zone_id = data.cloudflare_zone.zone.id
  rules {
    action = "set_cache_settings"
    action_parameters {
      cache = true
      edge_ttl {
        default = 43200
        mode    = "override_origin"
        status_code_ttl {
          status_code_range {
            from = 400
          }
          value = -1
        }
      }
    }
    description = "narinfo"
    enabled     = true
    expression  = "(http.host eq \"${digitalocean_spaces_bucket.cache.name}\" and http.request.uri.path ne \"/nix-cache-info\" and ends_with(http.request.uri.path, \"narinfo\"))"
  }
  rules {
    action = "set_cache_settings"
    action_parameters {
      cache = true
      edge_ttl {
        default = 86400
        mode    = "override_origin"
      }
    }
    description = "cache-info"
    enabled     = true
    expression  = "(http.host eq \"${digitalocean_spaces_bucket.cache.name}\" and http.request.uri.path eq \"/nix-cache-info\")"
  }
  rules {
    action = "set_cache_settings"
    action_parameters {
      cache = true
      edge_ttl {
        default = 31536000
        mode    = "override_origin"
        status_code_ttl {
          status_code_range {
            from = 400
          }
          value = 7200
        }
      }
    }
    description = "nar"
    enabled     = true
    expression  = "(http.host eq \"${digitalocean_spaces_bucket.cache.name}\" and starts_with(http.request.uri.path, \"/nar/\"))"
  }
}


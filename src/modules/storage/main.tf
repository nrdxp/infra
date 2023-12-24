provider "digitalocean" {
  spaces_access_id  = var.access_id
  spaces_secret_key = var.secret_key
}

resource "digitalocean_spaces_bucket" "cache" {
  for_each = toset(var.zones)
  name     = "${var.bucket}.${data.cloudflare_zone.zone[each.key].name}"
  region   = var.region
}

resource "digitalocean_spaces_bucket_policy" "cache" {
  for_each = toset(var.zones)
  region   = digitalocean_spaces_bucket.cache[each.key].region
  bucket   = digitalocean_spaces_bucket.cache[each.key].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Sid = "PublicReadGetObject"
      Effect = "Allow"
      Principal = "*"
      Action = "s3:GetObject"
      Resource = ["${digitalocean_spaces_bucket.cache[each.key].urn}", "${digitalocean_spaces_bucket.cache[each.key].urn}/*"]
      Condition = {
        IpAddress = {
          "aws:SourceIp" = [
            "173.245.48.0/20",
            "103.21.244.0/22",
            "103.22.200.0/22",
            "103.31.4.0/22",
            "141.101.64.0/18",
            "108.162.192.0/18",
            "190.93.240.0/20",
            "188.114.96.0/20",
            "197.234.240.0/22",
            "198.41.128.0/17",
            "162.158.0.0/15",
            "104.16.0.0/12",
            "172.64.0.0/13",
            "131.0.72.0/22",
            "2400:cb00::/32",
            "2606:4700::/32",
            "2803:f800::/32",
            "2405:b500::/32",
            "2405:8100::/32",
            "2a06:98c0::/29",
            "2c0f:f248::/32"
          ]
        }
      }
    }
  })
}

provider "cloudflare" {}

data "cloudflare_zone" "zone" {
  for_each = toset(var.zones)
  name     = each.key
}

resource "cloudflare_record" "cache" {
  for_each = toset(var.zones)
  zone_id  = data.cloudflare_zone.zone[each.key].id
  name     = var.bucket
  value    = digitalocean_spaces_bucket.cache[each.key].endpoint
  type     = "CNAME"
  proxied  = true
}

resource "cloudflare_ruleset" "cache" {
  for_each = toset(var.zones)
  kind     = "zone"
  name     = "default"
  phase    = "http_request_cache_settings"
  zone_id  = data.cloudflare_zone.zone[each.key].id
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
    expression  = "(http.host eq \"${digitalocean_spaces_bucket.cache[each.key].name}\" and http.request.uri.path ne \"/nix-cache-info\" and ends_with(http.request.uri.path, \"narinfo\"))"
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
    expression  = "(http.host eq \"${digitalocean_spaces_bucket.cache[each.key].name}\" and http.request.uri.path eq \"/nix-cache-info\")"
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
    expression  = "(http.host eq \"${digitalocean_spaces_bucket.cache[each.key].name}\" and starts_with(http.request.uri.path, \"/nar/\"))"
  }
}

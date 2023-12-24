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
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = ["${digitalocean_spaces_bucket.cache[each.key].urn}", "${digitalocean_spaces_bucket.cache[each.key].urn}/*"]
      Condition = {
        IpAddress = {
          "aws:SourceIp" = data.cloudflare_ip_ranges.ips.cidr_blocks
        }
      }
    }
  })
}

resource "digitalocean_spaces_bucket_object" "index" {
  for_each     = toset(var.zones)
  region       = digitalocean_spaces_bucket.cache[each.key].region
  bucket       = digitalocean_spaces_bucket.cache[each.key].name
  key          = "nix-cache-info"
  content      = <<-EOT
                   StoreDir: /nix/store
                   WantMassQuery: 1
                   Priority: ${index(var.zones, each.key) * 10 + 50}
                 EOT
  content_type = "text/plain"
}

provider "cloudflare" {}

data "cloudflare_ip_ranges" "ips" {}

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

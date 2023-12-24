variable "region" {
  type = string
}

variable "bucket" {
  type = string
}

variable "policy" {
  type = string
}

variable "zones" {
  type = list(string)
}

variable "access_id" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}

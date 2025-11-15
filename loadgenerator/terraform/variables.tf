variable "public_key" {
  description = "SSH public key content"
  type        = string
}

variable "project" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "zone" {
  type        = string
  description = "GCP Zone"
}

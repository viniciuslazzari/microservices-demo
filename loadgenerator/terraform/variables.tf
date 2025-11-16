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

variable "run_time" {
  description = "Default run time for Locust (ex: 10m, 30s). Optional."
  type        = string
  default     = "5m"
}

variable "instance_name" {
  description = "Name prefix for the VM instance"
  type        = string
  default     = "loadgenerator"
}

variable "machine_type" {
  description = "GCE machine type for the load generator"
  type        = string
  default     = "e2-medium"
}

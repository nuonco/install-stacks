variable "nuon_install_id" {
  type = string
}

variable "name" {
  type        = string
  description = "Custom stack key; the bucket is named <install-id>-<name>."
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "parameters" {
  type        = map(string)
  default     = {}
  description = "Optional settings: location, versioning, force_destroy."
}

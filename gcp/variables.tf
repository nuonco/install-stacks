##
## Nuon-generated variables (provided via tfvars file)
##

variable "nuon_install_id" {
  type        = string
  description = "The Nuon install ID for this deployment."
}

variable "nuon_org_id" {
  type        = string
  description = "The Nuon organization ID."
}

variable "nuon_app_id" {
  type        = string
  description = "The Nuon application ID."
}

variable "runner_api_url" {
  type        = string
  description = "The URL of the Nuon runner API."
}

variable "runner_api_token" {
  type        = string
  sensitive   = true
  description = "The API token used by the runner to authenticate with the Nuon runner API."
}

variable "runner_id" {
  type        = string
  description = "The Nuon runner ID."
}

variable "runner_init_script_url" {
  type        = string
  description = "The URL of the runner initialization script."
}

variable "phone_home_url" {
  type        = string
  description = "The URL the module calls to report provisioning results back to Nuon."
}

##
## Customer-supplied variables (prompted at apply time)
##

variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID where Nuon runner infrastructure will be provisioned. The customer provides this value."
}

variable "gcp_region" {
  type        = string
  description = "The GCP region where Nuon runner infrastructure will be provisioned. The customer provides this value."
}

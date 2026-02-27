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
## IAM permissions (provided via tfvars file)
##

variable "provision_permissions" {
  type        = list(string)
  default     = []
  description = "GCP IAM permissions for the provision service account custom role."
}

variable "provision_predefined_role" {
  type        = string
  default     = ""
  description = "GCP predefined role to bind to the provision service account (e.g. roles/editor)."
}

variable "maintenance_permissions" {
  type        = list(string)
  default     = []
  description = "GCP IAM permissions for the maintenance service account custom role."
}

variable "maintenance_predefined_role" {
  type        = string
  default     = ""
  description = "GCP predefined role to bind to the maintenance service account (e.g. roles/editor)."
}

variable "deprovision_permissions" {
  type        = list(string)
  default     = []
  description = "GCP IAM permissions for the deprovision service account custom role."
}

variable "deprovision_predefined_role" {
  type        = string
  default     = ""
  description = "GCP predefined role to bind to the deprovision service account (e.g. roles/editor)."
}

variable "has_break_glass" {
  type        = bool
  default     = false
  description = "Whether to create break-glass service account and IAM resources."
}

variable "break_glass_permissions" {
  type        = list(string)
  default     = []
  description = "GCP IAM permissions for the break-glass service account custom role."
}

variable "break_glass_predefined_role" {
  type        = string
  default     = ""
  description = "GCP predefined role to bind to the break-glass service account (e.g. roles/editor)."
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

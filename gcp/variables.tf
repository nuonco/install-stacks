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

variable "break_glass_roles" {
  type = map(object({
    permissions     = list(string)
    predefined_role = string
    enabled         = bool
  }))
  default     = {}
  description = "Break-glass roles. Each key is the role name. Disabled by default; only created when enabled=true."
}

variable "custom_roles" {
  type = map(object({
    permissions     = list(string)
    predefined_role = string
    enabled         = bool
  }))
  default     = {}
  description = "Custom roles for app operations. Each key is the role name. Enabled by default."
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

  validation {
    condition = contains([
      "africa-south1",
      "asia-east1",
      "asia-east2",
      "asia-northeast1",
      "asia-northeast2",
      "asia-northeast3",
      "asia-south1",
      "asia-south2",
      "asia-southeast1",
      "asia-southeast2",
      "australia-southeast1",
      "australia-southeast2",
      "europe-central2",
      "europe-north1",
      "europe-southwest1",
      "europe-west1",
      "europe-west2",
      "europe-west3",
      "europe-west4",
      "europe-west6",
      "europe-west8",
      "europe-west9",
      "europe-west10",
      "europe-west12",
      "me-central1",
      "me-central2",
      "me-west1",
      "northamerica-northeast1",
      "northamerica-northeast2",
      "southamerica-east1",
      "southamerica-west1",
      "us-central1",
      "us-east1",
      "us-east4",
      "us-east5",
      "us-south1",
      "us-west1",
      "us-west2",
      "us-west3",
      "us-west4",
    ], var.gcp_region)
    error_message = "The gcp_region must be a valid GCP region (e.g. us-central1, europe-west1, asia-east1)."
  }
}

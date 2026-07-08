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
  default     = ""
  sensitive   = true
  description = "The API token used by the runner to authenticate with the Nuon runner API. Not needed when using init-mng-v2 (runner fetches its own token)."
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

variable "install_inputs" {
  type        = map(string)
  default     = {}
  description = "Customer-provided install inputs. Keys are input names, values are provided at apply time."
}

##
## IAM permissions (provided via tfvars file)
##

variable "provision_policies" {
  type        = map(list(string))
  default     = {}
  description = "GCP IAM policies for the provision service account. Each key becomes its own custom role."
}

variable "provision_predefined_role" {
  type        = string
  default     = ""
  description = "GCP predefined role to bind to the provision service account (e.g. roles/editor)."
}

variable "maintenance_policies" {
  type        = map(list(string))
  default     = {}
  description = "GCP IAM policies for the maintenance service account. Each key becomes its own custom role."
}

variable "maintenance_predefined_role" {
  type        = string
  default     = ""
  description = "GCP predefined role to bind to the maintenance service account (e.g. roles/editor)."
}

variable "deprovision_policies" {
  type        = map(list(string))
  default     = {}
  description = "GCP IAM policies for the deprovision service account. Each key becomes its own custom role."
}

variable "deprovision_predefined_role" {
  type        = string
  default     = ""
  description = "GCP predefined role to bind to the deprovision service account (e.g. roles/editor)."
}

variable "break_glass_roles" {
  type = map(object({
    policies        = map(list(string))
    predefined_role = string
    enabled         = bool
  }))
  default     = {}
  description = "Break-glass roles. Each key is the role name. Disabled by default; only created when enabled=true."
}

variable "custom_roles" {
  type = map(object({
    policies        = map(list(string))
    predefined_role = string
    enabled         = bool
  }))
  default     = {}
  description = "Custom roles for app operations. Each key is the role name. Enabled by default."
}

##
## Secrets (provided via tfvars file)
##

variable "auto_generate_secrets" {
  type        = list(string)
  default     = []
  description = "Names of secrets to auto-generate. Random values are created and stored in Secret Manager."
}

variable "secrets" {
  type = map(object({
    description = string
    required    = bool
    value       = string
  }))
  default     = {}
  sensitive   = true
  description = "Customer-provided secrets. Keys are secret names, values include the secret value to store in Secret Manager."
}

variable "has_gke_node_pool" {
  type        = bool
  default     = true
  description = "Whether to create a least-privilege service account for GKE node pools."
}

variable "gke_node_pool_sa_email" {
  type        = string
  default     = ""
  description = "Email of an existing GKE node pool service account. If provided, skips creating one."
}

variable "runner_machine_type" {
  type        = string
  default     = "e2-standard-4"
  description = "GCE machine type for the Nuon runner instance. Default e2-standard-4 (4 vCPU / 16 GB) covers pulumi-gcp Go compiles, which can spike >8 GB on the heaviest packages; override with a smaller type (e.g. e2-medium or e2-standard-2) for lighter installs."
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

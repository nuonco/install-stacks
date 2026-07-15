##
## Nuon data source — everything the tfvars used to carry (runner, permissions,
## roles, inputs) is now read from the Nuon control plane via the stack_config
## data source (see stack.tf). Only the values below remain as variables.
##

variable "phone_home_id" {
  type        = string
  default     = ""
  description = "Per-stack-version identifier from the Nuon control plane; used by the stack_config data source to fetch this install's configuration. When empty, the data source is not read and all values must come from the legacy variables (see legacy.tf)."
}

variable "api_url" {
  type        = string
  default     = "https://runner.nuon.co"
  description = "Base URL of the Nuon runner API, up to but excluding /v1."
}

##
## stack_config overrides — values fetched from the data source are the base;
## anything set in these variables layers on top and wins. Secret values are
## supplied here because the API returns secret metadata but not values.
##

variable "install_inputs" {
  type        = map(string)
  default     = {}
  description = "Install input overrides, keyed by name. Merged over install_inputs from the stack_config data source; keys set here win."
}

variable "secrets" {
  type = map(object({
    description = optional(string)
    required    = optional(bool)
    value       = optional(string)
  }))
  default     = {}
  sensitive   = true
  description = "Secret overrides keyed by name. Any field set here layers over (wins against) the value from the stack_config data source. Secret values are supplied here since the API does not return them."
}

##
## Customer-supplied variables (prompted at apply time)
##

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

variable "runner_enabled" {
  type        = bool
  default     = true
  description = "Whether to provision the runner VM (instance template, managed instance group). Set to false to skip the runner and only create networking, IAM, and secrets."
}

variable "runner_machine_type" {
  type        = string
  default     = "e2-medium"
  description = "GCE machine type for the Nuon runner instance. Defaults to e2-medium to match ctl-api's DefaultGCPInstanceType; override with a larger type (e.g. e2-standard-4) for heavier installs — pulumi-gcp Go compiles can spike >8 GB."
}

variable "gcp" {
  type = object({
    project_id = string
    region     = string
  })
  default     = null
  description = "Customer-supplied GCP target: the project ID and region where Nuon runner infrastructure will be provisioned. Optional — when unset, the legacy gcp_project_id / gcp_region variables are used."

  validation {
    condition = var.gcp == null ? true : contains([
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
      "asia-southeast3",
      "australia-southeast1",
      "australia-southeast2",
      "europe-central2",
      "europe-north1",
      "europe-north2",
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
      "northamerica-south1",
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
    ], var.gcp.region)
    error_message = "The gcp.region must be a valid GCP region (e.g. us-central1, europe-west1, asia-east1)."
  }
}

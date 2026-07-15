##
## Nuon data source — everything the tfvars used to carry (runner, permissions,
## roles, inputs) is now read from the Nuon control plane via the stack_config
## data source (see stack.tf). Only the values below remain as variables.
##

variable "phone_home_id" {
  type        = string
  description = "Per-stack-version identifier from the Nuon control plane; used by the stack_config data source to fetch this install's configuration."
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

variable "runner_enabled" {
  type        = bool
  default     = true
  description = "Whether to provision the runner module (ASG, launch template, log group). Set to false to skip the runner and only create networking, IAM, and secrets."
}

variable "runner_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 instance type for the Nuon runner instance. Override with a larger type (e.g. t3.large) for installs with heavy build jobs."
}

##
## Customer-supplied variables (prompted at apply time)
##

variable "aws" {
  type = object({
    region = string
  })
  description = "Customer-supplied AWS target: the region where Nuon runner infrastructure will be provisioned."

  validation {
    condition = contains([
      "us-east-1",
      "us-east-2",
      "us-west-1",
      "us-west-2",
      "ca-central-1",
      "ca-west-1",
      "eu-north-1",
      "eu-west-1",
      "eu-west-2",
      "eu-west-3",
      "eu-central-1",
      "eu-central-2",
      "eu-south-1",
      "eu-south-2",
      "ap-east-1",
      "ap-northeast-1",
      "ap-northeast-2",
      "ap-northeast-3",
      "ap-south-1",
      "ap-south-2",
      "ap-southeast-1",
      "ap-southeast-2",
      "ap-southeast-3",
      "ap-southeast-4",
      "me-south-1",
      "me-central-1",
      "sa-east-1",
      "af-south-1",
    ], var.aws.region)
    error_message = "The aws.region must be a valid AWS region (e.g. us-east-1, eu-west-1)."
  }
}

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

variable "nuon_control_plane_account_ids" {
  type        = list(string)
  default     = []
  description = "AWS account IDs of the Nuon control plane that may assume the provision/maintenance/deprovision roles. Provided in the vendor tfvars."
}

##
## IAM permissions (provided via tfvars file)
##
## permissions: list of IAM action strings granted via an inline policy.
## managed_policy_arns: AWS managed (or customer-managed) policy ARNs to attach.
##

variable "provision_permissions" {
  type        = list(string)
  default     = []
  description = "IAM action strings granted to the provision role via an inline policy."
}

variable "provision_managed_policy_arns" {
  type        = list(string)
  default     = []
  description = "Managed policy ARNs to attach to the provision role (e.g. arn:aws:iam::aws:policy/AdministratorAccess)."
}

variable "maintenance_permissions" {
  type        = list(string)
  default     = []
  description = "IAM action strings granted to the maintenance role via an inline policy."
}

variable "maintenance_managed_policy_arns" {
  type        = list(string)
  default     = []
  description = "Managed policy ARNs to attach to the maintenance role."
}

variable "deprovision_permissions" {
  type        = list(string)
  default     = []
  description = "IAM action strings granted to the deprovision role via an inline policy."
}

variable "deprovision_managed_policy_arns" {
  type        = list(string)
  default     = []
  description = "Managed policy ARNs to attach to the deprovision role."
}

variable "break_glass_roles" {
  type = map(object({
    permissions         = list(string)
    managed_policy_arns = list(string)
    enabled             = bool
  }))
  default     = {}
  description = "Break-glass roles. Each key is the role name. Disabled by default; only created when enabled=true."
}

variable "custom_roles" {
  type = map(object({
    permissions         = list(string)
    managed_policy_arns = list(string)
    enabled             = bool
  }))
  default     = {}
  description = "Custom roles for app operations. Each key is the role name. Enabled when enabled=true."
}

##
## Secrets (provided via tfvars file)
##

variable "auto_generate_secrets" {
  type        = list(string)
  default     = []
  description = "Names of secrets to auto-generate. Random values are created and stored in AWS Secrets Manager."
}

variable "secrets" {
  type = map(object({
    description = string
    required    = bool
    value       = string
  }))
  default     = {}
  sensitive   = true
  description = "Customer-provided secrets. Keys are secret names, values include the secret value to store in AWS Secrets Manager."
}

##
## Customer-supplied variables (prompted at apply time)
##

variable "aws_region" {
  type        = string
  description = "The AWS region where Nuon runner infrastructure will be provisioned. The customer provides this value."

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
    ], var.aws_region)
    error_message = "The aws_region must be a valid AWS region (e.g. us-east-1, eu-west-1)."
  }
}

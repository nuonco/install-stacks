##
## Legacy (pre-provider) variables — backward compatibility.
##
## Before the stack_config data source, ctl-api rendered every value into
## inputs.auto.tfvars. These variables let an old-style tfvars file keep
## working against this module: when a legacy value is set it wins; otherwise
## the value is read from the stack_config data source (see stack.tf). All are
## optional so a new-style (provider) tfvars can omit them entirely.
##

variable "nuon_install_id" {
  type        = string
  default     = ""
  description = "Legacy: Nuon install ID. Read from stack_config when unset."
}

variable "nuon_org_id" {
  type        = string
  default     = ""
  description = "Legacy: Nuon organization ID. Read from stack_config when unset."
}

variable "nuon_app_id" {
  type        = string
  default     = ""
  description = "Legacy: Nuon application ID. Read from stack_config when unset."
}

variable "runner_api_url" {
  type        = string
  default     = ""
  description = "Legacy: Nuon runner API URL. Read from stack_config when unset."
}

variable "runner_id" {
  type        = string
  default     = ""
  description = "Legacy: Nuon runner ID. Read from stack_config when unset."
}

variable "phone_home_url" {
  type        = string
  default     = ""
  description = "Legacy: phone-home URL. Read from stack_config when unset."
}

variable "aws_region" {
  type        = string
  default     = ""
  description = "Legacy flat AWS region. Superseded by aws = { region }; read from stack_config when both are unset."
}

variable "nuon_support_iam_role_arns" {
  type        = list(string)
  default     = []
  description = "Legacy: Nuon control-plane IAM role ARNs allowed to assume the operation roles. Read from stack_config when empty."
}

variable "provision_permissions" {
  type        = list(string)
  default     = []
  description = "Legacy: provision role inline-policy IAM actions. Read from stack_config when empty."
}

variable "provision_inline_policy_document" {
  type        = string
  default     = ""
  description = "Legacy: provision role inline policy document JSON. Read from stack_config when unset."
}

variable "provision_managed_policy_arns" {
  type        = list(string)
  default     = []
  description = "Legacy: managed policy ARNs attached to the provision role. Read from stack_config when empty."
}

variable "maintenance_permissions" {
  type        = list(string)
  default     = []
  description = "Legacy: maintenance role inline-policy IAM actions. Read from stack_config when empty."
}

variable "maintenance_inline_policy_document" {
  type        = string
  default     = ""
  description = "Legacy: maintenance role inline policy document JSON. Read from stack_config when unset."
}

variable "maintenance_managed_policy_arns" {
  type        = list(string)
  default     = []
  description = "Legacy: managed policy ARNs attached to the maintenance role. Read from stack_config when empty."
}

variable "deprovision_permissions" {
  type        = list(string)
  default     = []
  description = "Legacy: deprovision role inline-policy IAM actions. Read from stack_config when empty."
}

variable "deprovision_inline_policy_document" {
  type        = string
  default     = ""
  description = "Legacy: deprovision role inline policy document JSON. Read from stack_config when unset."
}

variable "deprovision_managed_policy_arns" {
  type        = list(string)
  default     = []
  description = "Legacy: managed policy ARNs attached to the deprovision role. Read from stack_config when empty."
}

variable "break_glass_roles" {
  type = map(object({
    permissions            = optional(list(string), [])
    inline_policy_document = optional(string, "")
    managed_policy_arns    = optional(list(string), [])
    enabled                = bool
  }))
  default     = {}
  description = "Legacy: break-glass roles. Read from stack_config when empty."
}

variable "custom_roles" {
  type = map(object({
    permissions            = optional(list(string), [])
    inline_policy_document = optional(string, "")
    managed_policy_arns    = optional(list(string), [])
    enabled                = bool
  }))
  default     = {}
  description = "Legacy: custom roles. Read from stack_config when empty."
}

variable "auto_generate_secrets" {
  type        = list(string)
  default     = []
  description = "Legacy: names of secrets to auto-generate. Read from stack_config when empty."
}

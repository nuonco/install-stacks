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

variable "runner_api_token" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Legacy: runner API token. Read from stack_config when unset."
}

variable "runner_init_script_url" {
  type        = string
  default     = ""
  description = "Legacy: runner bootstrap script URL. Read from stack_config when unset."
}

variable "phone_home_url" {
  type        = string
  default     = ""
  description = "Legacy: phone-home URL. Read from stack_config when unset."
}

variable "provision_policies" {
  type        = map(list(string))
  default     = {}
  description = "Legacy: provision per-policy custom roles. Read from stack_config when empty."
}

variable "provision_predefined_role" {
  type        = string
  default     = ""
  description = "Legacy: provision predefined role. Read from stack_config when unset."
}

variable "maintenance_policies" {
  type        = map(list(string))
  default     = {}
  description = "Legacy: maintenance per-policy custom roles. Read from stack_config when empty."
}

variable "maintenance_predefined_role" {
  type        = string
  default     = ""
  description = "Legacy: maintenance predefined role. Read from stack_config when unset."
}

variable "deprovision_policies" {
  type        = map(list(string))
  default     = {}
  description = "Legacy: deprovision per-policy custom roles. Read from stack_config when empty."
}

variable "deprovision_predefined_role" {
  type        = string
  default     = ""
  description = "Legacy: deprovision predefined role. Read from stack_config when unset."
}

# Object shape matches the stack_config gcp role element so the legacy-vs-data-source
# conditionals in stack.tf type-unify.
variable "break_glass_roles" {
  type = map(object({
    permissions     = optional(list(string), [])
    policies        = optional(map(list(string)), {})
    predefined_role = optional(string, "")
    enabled         = optional(bool, false)
  }))
  default     = {}
  description = "Legacy: break-glass roles. Read from stack_config when empty."
}

variable "custom_roles" {
  type = map(object({
    permissions     = optional(list(string), [])
    policies        = optional(map(list(string)), {})
    predefined_role = optional(string, "")
    enabled         = optional(bool, false)
  }))
  default     = {}
  description = "Legacy: custom roles. Read from stack_config when empty."
}

variable "auto_generate_secrets" {
  type        = list(string)
  default     = []
  description = "Legacy: names of secrets to auto-generate. Read from stack_config when empty."
}

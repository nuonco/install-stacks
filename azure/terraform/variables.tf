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

variable "provision_permissions" {
  type        = list(string)
  default     = []
  description = "Azure actions for the provision identity custom role definition."
}

variable "provision_predefined_role" {
  type        = string
  default     = ""
  description = "Azure built-in role to assign to the provision identity (e.g. Contributor)."
}

variable "maintenance_permissions" {
  type        = list(string)
  default     = []
  description = "Azure actions for the maintenance identity custom role definition."
}

variable "maintenance_predefined_role" {
  type        = string
  default     = ""
  description = "Azure built-in role to assign to the maintenance identity (e.g. Contributor)."
}

variable "deprovision_permissions" {
  type        = list(string)
  default     = []
  description = "Azure actions for the deprovision identity custom role definition."
}

variable "deprovision_predefined_role" {
  type        = string
  default     = ""
  description = "Azure built-in role to assign to the deprovision identity (e.g. Contributor)."
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
## Secrets (provided via tfvars file)
##

variable "auto_generate_secrets" {
  type        = list(string)
  default     = []
  description = "Names of secrets to auto-generate. Random values are created and stored in Key Vault."
}

variable "secrets" {
  type = map(object({
    description = string
    required    = bool
    value       = string
  }))
  default     = {}
  sensitive   = true
  description = "Customer-provided secrets. Keys are secret names, values include the secret value to store in Key Vault."
}

##
## Customer-supplied variables (prompted at apply time)
##

variable "azure_subscription_id" {
  type        = string
  description = "The Azure subscription ID where Nuon runner infrastructure will be provisioned."
}

variable "azure_resource_group_name" {
  type        = string
  description = "The name of the Azure resource group where Nuon runner infrastructure will be provisioned. Must already exist."
}

variable "services" {
  type        = list(string)
  default     = []
  description = "List of Azure resource providers to register (e.g. Microsoft.ContainerService, Microsoft.KeyVault)."
}

variable "azure_location" {
  type        = string
  description = "The Azure region where Nuon runner infrastructure will be provisioned."

  validation {
    condition = contains([
      "australiacentral",
      "australiaeast",
      "australiasoutheast",
      "brazilsouth",
      "canadacentral",
      "canadaeast",
      "centralindia",
      "centralus",
      "eastasia",
      "eastus",
      "eastus2",
      "francecentral",
      "germanywestcentral",
      "japaneast",
      "japanwest",
      "koreacentral",
      "northcentralus",
      "northeurope",
      "norwayeast",
      "polandcentral",
      "qatarcentral",
      "southafricanorth",
      "southcentralus",
      "southeastasia",
      "swedencentral",
      "switzerlandnorth",
      "uaenorth",
      "uksouth",
      "ukwest",
      "westcentralus",
      "westeurope",
      "westus",
      "westus2",
      "westus3",
    ], var.azure_location)
    error_message = "The azure_location must be a valid Azure region (e.g. eastus, westeurope, southeastasia)."
  }
}

##
## Network configuration
##

variable "vnet_cidr" {
  type        = string
  default     = "10.128.0.0/16"
  description = "CIDR block for the virtual network."
}

variable "public_subnet_1_cidr" {
  type        = string
  default     = "10.128.0.0/26"
  description = "CIDR block for public subnet zone 1."
}

variable "public_subnet_2_cidr" {
  type        = string
  default     = "10.128.0.64/26"
  description = "CIDR block for public subnet zone 2."
}

variable "public_subnet_3_cidr" {
  type        = string
  default     = "10.128.0.128/26"
  description = "CIDR block for public subnet zone 3."
}

variable "runner_subnet_cidr" {
  type        = string
  default     = "10.128.128.0/24"
  description = "CIDR block for the runner subnet."
}

variable "private_subnet_1_cidr" {
  type        = string
  default     = "10.128.130.0/24"
  description = "CIDR block for private subnet zone 1."
}

variable "private_subnet_2_cidr" {
  type        = string
  default     = "10.128.132.0/24"
  description = "CIDR block for private subnet zone 2."
}

variable "private_subnet_3_cidr" {
  type        = string
  default     = "10.128.134.0/24"
  description = "CIDR block for private subnet zone 3."
}

variable "runner_ssh_public_key" {
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDNnSz9UjUE3hh8TxnJfY1Xg2n6e6hH0rWk0E9YWnKtLQRP8U7VqEMjlLXWZ9gqkqbfLBDFm5MaRp5MT8cJyUW3VKafMFZIcmIkUmhGW2Y70PJEIFy1jHGYghkmdVnApkm4Zk2iNJMR0FqFz+xm7yKMfjOkHKCf3tfn2zn1Y3S3VRpjPj7i1p5r5VCyVF3NpuZxE1dpfOMO/5SjJGq+C5AOhXM7dcP5HAg4HskmPPpJhfSz0lGi/n0NKTFzKnl1jP3fHY7L6AIjy0ePj+vNqEBhzpSK0VZMJW+X6kfT5USMd6BSh1Rp7R0m2yfivFCfFB3Gl+E9coHtjCR63ZJFRs3p7aiFSpq8fXwqb/v5bVip6Y3etfSnTGAP9/VxVnXIljCO1vJaRpPqw2gE9OnXYwJ6X2fxFLi0rkxT1kXvwr+JOhM14rDYSJA2iz11BvztjnD6wxIPFkTxaBmPK2c6/J6h5XJLN8TuZHGBKrT5MQbPPAWCIwH9T0aSD5VTb0="
  description = "SSH public key for the runner VMSS admin user."
}

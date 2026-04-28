output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "region" {
  value = var.aws_region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  value = module.vpc.private_subnet_id
}

output "runner_subnet_id" {
  value = module.vpc.runner_subnet_id
}

output "runner_security_group_id" {
  value = module.vpc.runner_security_group_id
}

output "runner_role_arn" {
  value = aws_iam_role.runner.arn
}

output "runner_instance_profile_arn" {
  value = aws_iam_instance_profile.runner.arn
}

output "runner_asg_name" {
  value = module.runner.asg_name
}

output "runner_log_group_name" {
  value = module.runner.log_group_name
}

output "provision_role_arn" {
  value = local.has_provision ? aws_iam_role.provision[0].arn : null
}

output "maintenance_role_arn" {
  value = local.has_maintenance ? aws_iam_role.maintenance[0].arn : null
}

output "deprovision_role_arn" {
  value = local.has_deprovision ? aws_iam_role.deprovision[0].arn : null
}

output "break_glass_role_arns" {
  value       = local.break_glass_role_arns
  description = "Map of break-glass role name to IAM role ARN."
}

output "custom_role_arns" {
  value       = local.custom_role_arns
  description = "Map of custom role name to IAM role ARN."
}

output "secret_arns" {
  value       = local.all_secret_arns
  description = "Map of {name}_secret_arn to AWS Secrets Manager ARN."
}

output "install_inputs" {
  value       = var.install_inputs
  description = "Customer-provided install inputs passed back to Nuon."
}

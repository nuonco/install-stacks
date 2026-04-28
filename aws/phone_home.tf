locals {
  break_glass_role_arns = { for k, v in aws_iam_role.break_glass : k => v.arn }
  custom_role_arns      = { for k, v in aws_iam_role.custom : k => v.arn }

  auto_generate_secret_arns = {
    for k, v in aws_secretsmanager_secret.auto_generate :
    "${k}_secret_arn" => v.arn
  }
  customer_secret_arns = {
    for k, v in aws_secretsmanager_secret.customer :
    "${k}_secret_arn" => v.arn
  }
  all_secret_arns = merge(local.auto_generate_secret_arns, local.customer_secret_arns)

  phone_home_payload = merge({
    request_type             = "Create"
    phone_home_type          = "aws"
    aws_account_id           = data.aws_caller_identity.current.account_id
    region                   = var.aws_region
    vpc_id                   = module.vpc.vpc_id
    public_subnet_id         = module.vpc.public_subnet_id
    private_subnet_id        = module.vpc.private_subnet_id
    runner_subnet_id         = module.vpc.runner_subnet_id
    runner_security_group_id = module.vpc.runner_security_group_id
    runner_role_arn          = aws_iam_role.runner.arn
    runner_instance_profile  = aws_iam_instance_profile.runner.arn
    runner_asg_name          = module.runner.asg_name
    runner_log_group_name    = module.runner.log_group_name
    provision_role_arn       = local.has_provision ? aws_iam_role.provision[0].arn : ""
    maintenance_role_arn     = local.has_maintenance ? aws_iam_role.maintenance[0].arn : ""
    deprovision_role_arn     = local.has_deprovision ? aws_iam_role.deprovision[0].arn : ""
    break_glass_role_arns    = local.break_glass_role_arns
    custom_role_arns         = local.custom_role_arns
    install_inputs           = var.install_inputs
  }, local.all_secret_arns)
}

resource "null_resource" "phone_home" {
  depends_on = [
    module.vpc,
    module.runner,
    aws_iam_role.runner,
    aws_iam_role.provision,
    aws_iam_role.maintenance,
    aws_iam_role.deprovision,
    aws_iam_role.break_glass,
    aws_iam_role.custom,
    aws_secretsmanager_secret_version.auto_generate,
    aws_secretsmanager_secret_version.customer,
  ]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -sf -X POST '${var.phone_home_url}' \
        -H 'Content-Type: application/json' \
        -d '${jsonencode(local.phone_home_payload)}'
    EOT
  }
}

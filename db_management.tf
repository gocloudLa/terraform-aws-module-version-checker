/*----------------------------------------------------------------------*/
/* DB USER MANAGEMENT                                                   */
/*----------------------------------------------------------------------*/
module "db_management" {
  source = "./modules/aws/terraform-aws-db-management/"

  for_each = var.rds_parameters

  create      = try(each.value.enable_db_management, var.rds_defaults.enable_db_management, false)
  name        = "${local.common_name}-${each.key}-db-management"
  description = "Manage db users for database in ${local.common_name}-${each.key}"

  vpc_subnet_ids         = data.aws_subnets.this[each.key].ids
  vpc_security_group_ids = [data.aws_security_group.default[each.key].id]
  attach_network_policy  = true

  engine = try(each.value.engine, var.rds_defaults.engine, null)

  secret_name = try(each.value.secret.name, var.rds_defaults.secret.name, "rds-${local.common_name}-${each.key}")
  secret_arn  = try(aws_secretsmanager_secret.this[each.key].arn, null)
  timeout     = try(each.value.db_management_timeout, var.rds_defaults.db_management_timeout, 300)
  memory_size = try(each.value.db_management_memory_size, var.rds_defaults.db_management_memory_size, 256)

  cloudwatch_logs_retention_in_days = try(each.value.cloudwatch_logs_retention_in_days, var.rds_defaults.cloudwatch_logs_retention_in_days, 14)

  parameters = try(each.value.db_management_parameters, {})

  enable_logs_notifications        = try(each.value.enable_db_management_logs_notifications, var.rds_defaults.enable_db_management_logs_notifications, false)
  logs_notifications_function_name = try(each.value.db_management_logs_notifications_lambda_name, var.rds_defaults.db_management_logs_notifications_lambda_name, "${local.common_name_prefix}-notifications")

  tags = local.common_tags
}
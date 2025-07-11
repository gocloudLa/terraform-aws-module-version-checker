/*----------------------------------------------------------------------*/
/* DB DUMP CREATE                                                       */
/*----------------------------------------------------------------------*/
module "db_dump_create" {
  source = "./modules/aws/terraform-aws-db-dump-create/"

  for_each = var.rds_parameters

  create      = try(each.value.enable_db_dump_create, var.rds_defaults.enable_db_dump_create, false)
  name        = "${local.common_name}-${each.key}-db-dump-create"
  description = "Create a db dump for database in ${local.common_name}-${each.key}"
  engine      = try(each.value.engine, var.rds_defaults.engine, null)

  vpc_subnet_ids         = data.aws_subnets.this[each.key].ids
  vpc_security_group_ids = [data.aws_security_group.default[each.key].id]
  attach_network_policy  = true

  secret_name = try(each.value.secret.name, var.rds_defaults.secret.name, "rds-${local.common_name}-${each.key}")
  secret_arn  = try(aws_secretsmanager_secret.this[each.key].arn, null)
  db_name     = try(each.value.db_dump_create_db_name, var.rds_defaults.db_dump_create_db_name, "")
  timeout     = try(each.value.db_dump_create_timeout, var.rds_defaults.db_dump_create_timeout, 300)
  memory_size = try(each.value.db_dump_create_memory_size, var.rds_defaults.db_dump_create_memory_size, 256)

  cloudwatch_logs_retention_in_days = try(each.value.cloudwatch_logs_retention_in_days, var.rds_defaults.cloudwatch_logs_retention_in_days, 14)

  schedule_expression        = try(each.value.db_dump_create_schedule_expression, var.rds_defaults.db_dump_create_schedule_expression, "")
  s3_arn_permission_accounts = try(each.value.db_dump_create_s3_arn_permission_accounts, var.rds_defaults.db_dump_create_s3_arn_permission_accounts, [])
  retention_in_days          = try(each.value.db_dump_create_retention_in_days, var.rds_defaults.db_dump_create_retention_in_days, 2)
  local_path_custom_scripts  = try(each.value.db_dump_create_local_path_custom_scripts, var.rds_defaults.db_dump_create_local_path_custom_scripts, "")

  tags = local.common_tags
}

/*----------------------------------------------------------------------*/
/* DB DUMP RESTORE                                                      */
/*----------------------------------------------------------------------*/
module "db_dump_restore" {
  source = "./modules/aws/terraform-aws-db-dump-restore/"

  for_each = var.rds_parameters

  create      = try(each.value.enable_db_dump_restore, var.rds_defaults.enable_db_dump_restore, false)
  name        = "${local.common_name}-${each.key}-db-dump-restore"
  description = "Restore a db dump for database in ${local.common_name}-${each.key}"
  engine      = try(each.value.engine, var.rds_defaults.engine, null)

  vpc_subnet_ids         = data.aws_subnets.this[each.key].ids
  vpc_security_group_ids = [data.aws_security_group.default[each.key].id]
  attach_network_policy  = true

  secret_name = try(each.value.secret.name, var.rds_defaults.secret.name, "rds-${local.common_name}-${each.key}")
  secret_arn  = try(aws_secretsmanager_secret.this[each.key].arn, null)
  db_name     = try(each.value.db_dump_restore_db_name, var.rds_defaults.db_dump_restore_db_name, "")
  timeout     = try(each.value.db_dump_restore_timeout, var.rds_defaults.db_dump_restore_timeout, 300)
  memory_size = try(each.value.db_dump_restore_memory_size, var.rds_defaults.db_dump_restore_memory_size, 256)

  cloudwatch_logs_retention_in_days = try(each.value.cloudwatch_logs_retention_in_days, var.rds_defaults.cloudwatch_logs_retention_in_days, 14)

  s3_bucket_name = try(each.value.db_dump_restore_s3_bucket_name, var.rds_defaults.db_dump_restore_s3_bucket_name, "")

  tags = local.common_tags
}
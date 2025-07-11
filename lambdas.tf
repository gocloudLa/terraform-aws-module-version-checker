/*----------------------------------------------------------------------*/
/* Lambda-RDS Function                                                  */
/*----------------------------------------------------------------------*/
module "db_reset" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.7.1"

  for_each = var.rds_parameters

  create_function = try(each.value.enable_db_reset, var.rds_defaults.enable_db_reset, false)
  function_name   = "${local.common_name}-${each.key}-db-reset"
  description     = "Lambda function for re-creating a database in ${local.common_name}-${each.key}"
  handler         = "app.handler"
  runtime         = "python3.9"

  source_path = "${path.module}/lambdas/db-reset"
  ## Variable to avoid recreating the null_resource.archive that uploads the function code in every run
  recreate_missing_package = false

  layers = [aws_lambda_layer_version.db_reset[0].arn]

  vpc_subnet_ids         = data.aws_subnets.this[each.key].ids
  vpc_security_group_ids = [data.aws_security_group.default[each.key].id]
  attach_network_policy  = true

  environment_variables = { "SECRET_NAME" : try(each.value.secret.name, var.rds_defaults.secret.name, "rds-${local.common_name}-${each.key}") }

  attach_policy_statements = true
  policy_statements = {
    lambda = {
      effect    = "Allow",
      actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"],
      resources = [aws_secretsmanager_secret.this[each.key].arn]
    }
  }
  tags = local.common_tags
}

resource "aws_lambda_layer_version" "db_reset" {

  count = var.rds_parameters != {} ? 1 : 0

  filename    = "${path.module}/lambdas/layer/pymysql-layer.zip"
  description = "Custom layer with pymysql dependency for db-reset function"
  layer_name  = "${local.common_name}-pymysql"

  compatible_runtimes = ["python3.9"]

}

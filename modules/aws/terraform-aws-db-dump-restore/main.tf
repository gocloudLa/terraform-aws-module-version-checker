module "lambda_restore_dump" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.20.0"

  count = local.condition_create ? 1 : 0

  function_name = var.name
  description   = var.description
  handler       = "index.lambda_handler"
  runtime       = "python3.13"

  memory_size = var.memory_size
  timeout     = var.timeout

  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  attach_network_policy  = var.attach_network_policy

  attach_policy_statements = true
  policy_statements = {
    s3_read = {
      effect = "Allow",
      actions = [
        "s3:GetObject"
      ],
      resources = [
        "${local.s3_bucket_arn}/*"
      ]
    }
    s3_list = {
      effect = "Allow",
      actions = [
        "s3:ListBucket"
      ],
      resources = [
        "${local.s3_bucket_arn}"
      ]
    }
    secrets_manager = {
      effect    = "Allow",
      actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"],
      resources = [var.secret_arn]
    }
  }

  layers      = [aws_lambda_layer_version.this[0].arn]
  source_path = local.lambda_source_path

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days

  environment_variables = {
    "SECRET_NAME" : "${var.secret_name}"
    "DB_NAME" : "${var.db_name}"
    "BUCKET_NAME" : "${var.s3_bucket_name}"
    "BUCKET_BACKUP_FILE" : local.backup_latest_name
    "BUCKET_CUSTOM_SCRIPTS_PATH" : "custom_scripts/"
  }

  tags = var.tags
}

resource "aws_lambda_layer_version" "this" {
  count = local.condition_create ? 1 : 0

  filename            = local.lambda_layer_filename
  description         = var.description
  layer_name          = var.name
  compatible_runtimes = ["python3.13"]
}
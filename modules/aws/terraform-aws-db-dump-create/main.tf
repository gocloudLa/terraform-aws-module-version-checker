module "lambda_create_dump" {
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

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    "${var.name}" = {
      principal  = "events.amazonaws.com"
      source_arn = module.eventbridge_create_dump[0].eventbridge_rule_arns["${var.name}"]
    }
  }

  attach_policy_statements = true
  policy_statements = {
    s3_write = {
      effect = "Allow",
      actions = [
        "s3:PutObject"
      ],
      resources = [
        "${module.s3_create_dump[0].s3_bucket_arn}/*"
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
    "BUCKET_NAME" : "${var.name}"
    "BACKUP_LATEST_NAME" : local.backup_latest_name
    "BACKUP_HISTORY_PATH" : "history/"
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

module "s3_create_dump" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.14.1"

  count = local.condition_create ? 1 : 0

  bucket                   = var.name
  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  versioning = {
    status     = false
    mfa_delete = false
  }

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.s3_arn_permission_accounts
        }
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          "${module.s3_create_dump[0].s3_bucket_arn}",
          "${module.s3_create_dump[0].s3_bucket_arn}/*"
        ]
      }
    ]
  })

  lifecycle_rule = [
    {
      id      = "delete_files_after_${var.retention_in_days}_days"
      enabled = true
      filter = {
        prefix = "history/"
      }

      expiration = {
        days = var.retention_in_days
      }
    },
  ]
}

module "s3_dump_objects" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "3.14.1"

  for_each    = local.condition_create_s3_dump_objects ? fileset(var.local_path_custom_scripts, "**") : []
  bucket      = module.s3_create_dump[0].s3_bucket_id
  key         = "custom_scripts/${each.value}"
  file_source = "${var.local_path_custom_scripts}/${each.value}"
  source_hash = filemd5("${var.local_path_custom_scripts}/${each.value}")
}

module "eventbridge_create_dump" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "1.17.1"

  count = local.condition_create ? 1 : 0

  role_name  = "${var.name}_event"
  create_bus = false

  rules = {
    "${var.name}" = {
      description         = "Run ${var.name} lambda function"
      schedule_expression = var.schedule_expression
    }
  }

  targets = {
    "${var.name}" = [
      {
        name = "${var.name}"
        arn  = module.lambda_create_dump[0].lambda_function_arn
        # attach_role_arn = true
      }
    ]
  }
}
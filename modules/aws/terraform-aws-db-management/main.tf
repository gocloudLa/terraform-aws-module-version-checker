module "lambda_db_management" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "5.3.0"

  count = local.condition_create ? 1 : 0

  function_name = var.name
  description   = var.description
  handler       = "index.lambda_handler"
  runtime       = "python3.12"

  memory_size = var.memory_size
  timeout     = var.timeout

  maximum_retry_attempts = 0

  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  attach_network_policy  = var.attach_network_policy

  attach_policy_statements = true
  policy_statements = {
    secrets_manager = {
      effect    = "Allow",
      actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"],
      resources = [var.secret_arn]
    }
    ssm_parameter = {
      effect    = "Allow",
      actions   = ["ssm:GetParameter"],
      resources = ["${module.ssm_parameter[0].ssm_parameter_arn}"]
    }
  }

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    "${var.name}" = {
      principal  = "events.amazonaws.com"
      source_arn = module.eventbridge[0].eventbridge_rule_arns["${var.name}"]
    }
  }

  layers      = [aws_lambda_layer_version.this[0].arn]
  source_path = local.lambda_source_path

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days

  environment_variables = {
    "SECRET_NAME" : "${var.secret_name}"
    "PARAMETER_NAME" : "${module.ssm_parameter[0].ssm_parameter_name}"
  }

  tags = var.tags
}

resource "aws_lambda_layer_version" "this" {
  count = local.condition_create ? 1 : 0

  filename            = local.lambda_layer_filename
  description         = var.description
  layer_name          = var.name
  compatible_runtimes = ["python3.12"]
}

module "ssm_parameter" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "1.1.0"

  count = local.condition_create ? 1 : 0

  name  = var.name
  value = jsonencode(var.parameters) #try(each.value.value, null)
  # values          = try(each.value.values, [])
  type        = "SecureString" #try(each.value.type, null)
  secure_type = true           # try(each.value.secure_type, true)
  # description     = try(each.value.description, null)
  # tier            = try(each.value.tier, null)
  # key_id          = try(each.value.key_id, null)
  # allowed_pattern = try(each.value.allowed_pattern, null)
  # data_type       = try(each.value.data_type, null)

  tags = var.tags
}

module "eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "1.17.1"

  count = local.condition_create ? 1 : 0

  role_name  = "${var.name}_event"
  create_bus = false

  rules = {
    "${var.name}" = {
      description = "Capture ${var.name} SSM Parameter change"
      event_pattern = jsonencode(
        {
          "source" : ["aws.ssm"],
          "resources" : ["${module.ssm_parameter[0].ssm_parameter_arn}"],
        }
      )
      enabled = true
    }
  }

  targets = {
    "${var.name}" = [
      {
        name = "${var.name}"
        arn  = module.lambda_db_management[0].lambda_function_arn
        # attach_role_arn = true
      }
    ]
  }
}

data "aws_lambda_function" "notifications" {
  count         = local.condition_logs_notifications ? 1 : 0
  function_name = var.logs_notifications_function_name
}

resource "aws_lambda_permission" "notifications" {
  count         = local.condition_logs_notifications ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.notifications[0].function_name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
  source_arn    = format("%s:*", module.lambda_db_management[0].lambda_cloudwatch_log_group_arn)
}

resource "aws_cloudwatch_log_subscription_filter" "notifications" {
  count           = local.condition_logs_notifications ? 1 : 0
  destination_arn = data.aws_lambda_function.notifications[0].arn
  filter_pattern  = "[w1!=START && w1!=END && w1!=INIT_START && w1!=REPORT, w2]"
  log_group_name  = module.lambda_db_management[0].lambda_cloudwatch_log_group_name
  name            = var.name
  depends_on      = [aws_lambda_permission.notifications[0]]
}
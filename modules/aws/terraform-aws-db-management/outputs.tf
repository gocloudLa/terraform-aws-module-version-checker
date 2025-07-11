# Lambda Function
output "lambda_function_arn" {
  description = "The ARN of the Lambda Function"
  value       = try(module.lambda_db_management.aws_lambda_function.this[0].arn, "")
}

output "lambda_function_name" {
  description = "The name of the Lambda Function"
  value       = try(module.lambda_db_management.aws_lambda_function.this[0].function_name, "")
}

output "lambda_role_arn" {
  description = "The ARN of the IAM role created for the Lambda Function"
  value       = try(module.lambda_db_management.aws_iam_role.lambda[0].arn, "")
}

output "lambda_role_name" {
  description = "The name of the IAM role created for the Lambda Function"
  value       = try(module.lambda_db_management.aws_iam_role.lambda[0].name, "")
}
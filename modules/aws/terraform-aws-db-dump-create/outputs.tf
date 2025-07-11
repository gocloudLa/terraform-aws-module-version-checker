# Lambda Function
output "lambda_function_arn" {
  description = "The ARN of the Lambda Function"
  value       = try(module.lambda_create_dump.aws_lambda_function.this[0].arn, "")
}

output "lambda_function_name" {
  description = "The name of the Lambda Function"
  value       = try(module.lambda_create_dump.aws_lambda_function.this[0].function_name, "")
}

output "lambda_role_arn" {
  description = "The ARN of the IAM role created for the Lambda Function"
  value       = try(module.lambda_create_dump.aws_iam_role.lambda[0].arn, "")
}

output "lambda_role_name" {
  description = "The name of the IAM role created for the Lambda Function"
  value       = try(module.lambda_create_dump.aws_iam_role.lambda[0].name, "")
}

# S3
output "s3_bucket_id" {
  description = "The name of the bucket."
  value       = try(module.s3_create_dump.aws_s3_bucket.this[0].id, "")
}

output "s3_bucket_arn" {
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
  value       = try(module.s3_create_dump.aws_s3_bucket.this[0].arn, "")
}
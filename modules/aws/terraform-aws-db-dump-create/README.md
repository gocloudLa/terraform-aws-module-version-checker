## Description:

This module creates the necessary resources to generate an SQL dump and store it in an S3 bucket along with cleanup scripts for the database.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eventbridge_create_dump"></a> [eventbridge\_create\_dump](#module\_eventbridge\_create\_dump) | terraform-aws-modules/eventbridge/aws | 1.17.1 |
| <a name="module_lambda_create_dump"></a> [lambda\_create\_dump](#module\_lambda\_create\_dump) | terraform-aws-modules/lambda/aws | 5.3.0 |
| <a name="module_s3_create_dump"></a> [s3\_create\_dump](#module\_s3\_create\_dump) | terraform-aws-modules/s3-bucket/aws | 3.14.1 |
| <a name="module_s3_dump_objects"></a> [s3\_dump\_objects](#module\_s3\_dump\_objects) | terraform-aws-modules/s3-bucket/aws//modules/object | 3.14.1 |

## Resources

| Name | Type |
|------|------|
| [aws_lambda_layer_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | resource |
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attach_network_policy"></a> [attach\_network\_policy](#input\_attach\_network\_policy) | Controls whether VPC/network policy should be added to IAM role for Lambda Function | `bool` | `false` | no |
| <a name="input_cloudwatch_logs_retention_in_days"></a> [cloudwatch\_logs\_retention\_in\_days](#input\_cloudwatch\_logs\_retention\_in\_days) | Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653. | `number` | `14` | no |
| <a name="input_create"></a> [create](#input\_create) | Set to create resources | `bool` | `true` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Name of the destination database | `string` | `""` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of your resources | `string` | `""` | no |
| <a name="input_local_path_custom_scripts"></a> [local\_path\_custom\_scripts](#input\_local\_path\_custom\_scripts) | Path where SQL scripts to be executed are located | `string` | `""` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | The amount of memory size your Lambda Function has to run in mb. | `number` | `256` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of your resources | `string` | `""` | no |
| <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days) | Specifies the number of days you want to retain dumps in s3 | `number` | `2` | no |
| <a name="input_s3_arn_permission_accounts"></a> [s3\_arn\_permission\_accounts](#input\_s3\_arn\_permission\_accounts) | List of ARNs of root accounts that will be granted access to the bucket | `list(string)` | `[]` | no |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | Schedule expression for eventBridge | `string` | `"cron(0 * * * ? *)"` | no |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | Name of the secret holding the database connection. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | The amount of time your Lambda Function has to run in seconds. | `number` | `300` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of security group ids when Lambda Function should run in the VPC. | `list(string)` | `null` | no |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | List of subnet ids when Lambda Function should run in the VPC. Usually private or intra subnets. | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | The ARN of the Lambda Function |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | The name of the Lambda Function |
| <a name="output_lambda_role_arn"></a> [lambda\_role\_arn](#output\_lambda\_role\_arn) | The ARN of the IAM role created for the Lambda Function |
| <a name="output_lambda_role_name"></a> [lambda\_role\_name](#output\_lambda\_role\_name) | The name of the IAM role created for the Lambda Function |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | The ARN of the bucket. Will be of format arn:aws:s3:::bucketname. |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | The name of the bucket. |


## Note

It is necessary to have a layer with the mysqldump binary generated from the image that runs by default in the aws lambda.

Information: [AWS Lambda Runtimes](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html)

#### Steps to generate it if required:
- Run the command: `docker run --rm -it -v $(pwd):/app --entrypoint /bin/sh amazonlinux:version`
- Execute: `yum update`
- Execute: `yum install mysql which zip -y`
- Run and copy the directory: `which mysqldump`
- Zip the directory: `zip /app/mysqldump.zip directory_of_mysqldump`
- Apply permissions: `chmod 777 /app/mysqldump.zip`
- Exit the container: `exit`

Subsequently, insert the generated zip into the layer directory.

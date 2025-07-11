/*----------------------------------------------------------------------*/
/* General | Variable Definition                                        */
/*----------------------------------------------------------------------*/

variable "create" {
  type        = bool
  description = "Set to create resources"
  default     = true
}

variable "name" {
  type        = string
  description = "Name of your resources"
  default     = ""
}

variable "description" {
  type        = string
  description = "Description of your resources"
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "engine" {
  description = "Engine type ( mysql / postgresql)."
  type        = string
  default     = "mysql"
}

/*----------------------------------------------------------------------*/
/* Lambdas | Variable Definition                                         */
/*----------------------------------------------------------------------*/

variable "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds."
  type        = number
  default     = 300
}

variable "memory_size" {
  description = "The amount of memory size your Lambda Function has to run in mb."
  type        = number
  default     = 256
}

variable "vpc_subnet_ids" {
  description = "List of subnet ids when Lambda Function should run in the VPC. Usually private or intra subnets."
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "List of security group ids when Lambda Function should run in the VPC."
  type        = list(string)
  default     = null
}

variable "attach_network_policy" {
  description = "Controls whether VPC/network policy should be added to IAM role for Lambda Function"
  type        = bool
  default     = false
}

variable "cloudwatch_logs_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653."
  type        = number
  default     = 14
}

variable "schedule_expression" {
  type        = string
  description = "Schedule expression for eventBridge"
  default     = "cron(0 * * * ? *)" #1hour
}

variable "s3_arn_permission_accounts" {
  type        = list(string)
  description = "List of ARNs of root accounts that will be granted access to the bucket"
  default     = []
}

variable "retention_in_days" {
  type        = number
  description = "Specifies the number of days you want to retain dumps in s3"
  default     = 7
}

variable "local_path_custom_scripts" {
  type        = string
  description = "Path where SQL scripts to be executed are located"
  default     = ""
}

variable "secret_name" {
  type        = string
  description = "Name of the secret holding the database connection."
  default     = ""
}

variable "secret_arn" {
  type        = string
  description = "ARN of the secret holding the database connection."
  default     = ""
}

variable "db_name" {
  type        = string
  description = "Name of the destination database"
  default     = ""
}
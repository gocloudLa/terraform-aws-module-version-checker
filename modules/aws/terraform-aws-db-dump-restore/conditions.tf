locals {

  condition_create = var.create && var.db_name != "" && var.s3_bucket_name != "" ? true : false
}

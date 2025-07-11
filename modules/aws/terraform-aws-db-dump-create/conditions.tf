locals {

  condition_create                 = var.create && var.db_name != "" ? true : false
  condition_create_s3_dump_objects = local.condition_create && var.local_path_custom_scripts != "" ? true : false
}

locals {
  lambda_source_path    = can(regex("mysql", var.engine)) || can(regex("mariadb", var.engine)) ? "${path.module}/lambda/create_dump_mysql" : "${path.module}/lambda/create_dump_pg"
  backup_latest_name    = can(regex("mysql", var.engine)) || can(regex("mariadb", var.engine)) ? "latest_backup.sql" : "latest_backup.dump"
  lambda_layer_filename = can(regex("mysql", var.engine)) || can(regex("mariadb", var.engine)) ? "${path.module}/lambda/layer/mysqldump.zip" : "${path.module}/lambda/layer/pgdump.zip"
}
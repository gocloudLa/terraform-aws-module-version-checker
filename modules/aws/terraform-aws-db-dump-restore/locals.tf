locals {
  s3_bucket_arn         = "arn:aws:s3:::${var.s3_bucket_name}"
  lambda_source_path    = can(regex("mysql", var.engine)) || can(regex("mariadb", var.engine)) ? "${path.module}/lambda/restore_dump_mysql" : "${path.module}/lambda/restore_dump_pg"
  backup_latest_name    = can(regex("mysql", var.engine)) || can(regex("mariadb", var.engine)) ? "latest_backup.sql" : "latest_backup.dump"
  lambda_layer_filename = can(regex("mysql", var.engine)) || can(regex("mariadb", var.engine)) ? "${path.module}/lambda/layer/mysql.zip" : "${path.module}/lambda/layer/pg.zip"
}

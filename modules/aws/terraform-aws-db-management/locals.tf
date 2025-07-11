locals {
  lambda_source_path    = can(regex("mysql", var.engine)) || can(regex("mariadb", var.engine)) ? "${path.module}/lambda/db_management_mysql" : "${path.module}/lambda/db_management_postgresql"
  lambda_layer_filename = can(regex("mysql", var.engine)) || can(regex("mariadb", var.engine)) ? "${path.module}/lambda/layer/pymysql-layer.zip" : "${path.module}/lambda/layer/psycopg2-layer.zip"
}
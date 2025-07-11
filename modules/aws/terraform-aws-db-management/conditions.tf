locals {

  condition_create             = var.create ? true : false
  condition_logs_notifications = var.create && var.enable_logs_notifications ? true : false
}

module "wrapper_rds" {
  source = "../../"

  metadata = local.metadata
  project  = local.project

  rds_parameters = {
    "mariadb-00" = {

      engine         = "mariadb"
      engine_version = "10.6.14"
      # DEBUG
      deletion_protection = false
      apply_immediately   = true
      skip_final_snapshot = true

      subnet_ids = data.aws_subnets.public.ids # Default: ""
      # subnet_name         = "${local.common_name_prefix}-public*" # Default: "${local.common_name_prefix}-private*"
      publicly_accessible = true
      ingress_with_cidr_blocks = [
        {
          rule        = "mysql-tcp"
          cidr_blocks = "0.0.0.0/0"
        }
      ]

      dns_records = {
        "" = {
          # zone_name    = local.zone_private
          # private_zone = true
          # DEBUG
          zone_name    = local.zone_public
          private_zone = false
        }
      }
      parameters = [
        {
          name  = "max_connections"
          value = "150"
        }
      ]
      maintenance_window      = "Sun:04:00-Sun:06:00"
      backup_window           = "03:00-03:30"
      backup_retention_period = "7"

      # enable_db_dump_restore = true
      # db_dump_restore_s3_bucket_name = "gcl-l04-core-00-db-dump-create"
      # db_dump_restore_db_name = "gocloud"

      # DB MANAGEMENT
      enable_db_management                    = true
      enable_db_management_logs_notifications = true
      # db_management_logs_notifications_lambda_name = "dmc-prd-notifications"
      db_management_parameters = {
        databases = [
          {
            name    = "mydb1"
            charset = "utf8mb4"
            collate = "utf8mb4_general_ci"
          },
          {
            name    = "mydb2"
            charset = "utf8mb4"
            collate = "utf8mb4_general_ci"
          },
          {
            name    = "mydb3"
            charset = "utf8mb4"
            collate = "utf8mb4_general_ci"
          }
        ],
        users = [
          {
            username = "user1"
            host     = "%"
            password = "password1"
            grants = [
              {
                database   = "mydb1"
                table      = "*"
                privileges = "ALL"
              },
              {
                database   = "mydb2"
                table      = "*"
                privileges = "SELECT, UPDATE"
              }
            ]
          },
          {
            username = "user2"
            host     = "%"
            password = "password2"
            grants = [
              {
                database   = "mydb2"
                table      = "*"
                privileges = "ALL"
              }
            ]
          }
        ],
        excluded_users = ["rdsadmin", "root", "mariadb.sys", "healthcheck", "rds_superuser_role", "mysql.infoschema", "mysql.session", "mysql.sys"]
      }
    }

    "pgsql-00" = {

      engine               = "postgres"
      engine_version       = "16"
      family               = "postgres16" # DB parameter group
      major_engine_version = "16"         # DB option group

      port = "5432"

      # DEBUG
      deletion_protection = false
      apply_immediately   = true
      skip_final_snapshot = true

      subnet_ids          = data.aws_subnets.public.ids
      publicly_accessible = true
      ingress_with_cidr_blocks = [
        {
          rule        = "postgresql-tcp"
          cidr_blocks = "0.0.0.0/0"
        }
      ]

      dns_records = {
        "" = {
          # zone_name    = local.zone_private
          # private_zone = true
          # DEBUG
          zone_name    = local.zone_public
          private_zone = false
        }
      }
      # parameters = [
      #   {
      #     name  = "max_connections"
      #     value = "150"
      #   }
      # ]
      maintenance_window      = "Sun:04:00-Sun:06:00"
      backup_window           = "03:00-03:30"
      backup_retention_period = "7"
      apply_immediately       = true

      # DB MANAGEMENT
      enable_db_management                    = true
      enable_db_management_logs_notifications = true
      db_management_parameters = {
        databases = [
          {
            "name" : "db1",
            "owner" : "root",
            "schemas" : [
              {
                "name" : "public",
                "owner" : "root"
              },
              {
                "name" : "schema1",
                "owner" : "usr1"
              }
            ]
          },
          {
            "name" : "db2",
            "owner" : "usr2",
          },
          {
            "name" : "db3",
            "owner" : "usr3",
          }
        ],
        roles = [
          { "rolename" : "example_role_1" },
          { "rolename" : "example_role_2" }
        ],
        users = [
          {
            "username" : "usr1",
            "password" : "passwd1",
            "grants" : [
              {
                "database" : "db1",
                "schema" : "public",
                "privileges" : "ALL PRIVILEGES",
                "table" : "*"
              }
            ]
          },
          {
            "username" : "usr2",
            "password" : "passwd2",
            "grants" : [
              {
                "privileges" : "example_role_1",
                "options" : "WITH SET TRUE"
              },
              {
                "privileges" : "example_role_2",
                "options" : "WITH SET TRUE"
              }
            ]
          },
          {
            "username" : "usr3",
            "password" : "passwd3",
            "grants" : []
          }
        ],
        excluded_users = ["rdsadmin", "root", "healthcheck"]
      }
    }

    "mysql-00" = {

      engine_version       = "8.0.37"
      major_engine_version = "8.0"
      engine               = "mysql"
      family               = "mysql8.0"

      # Monitoring & logs
      enabled_cloudwatch_logs_exports = ["error", "slowquery"]

      maintenance_window      = "Sun:04:00-Sun:06:00"
      backup_window           = "03:00-03:30"
      backup_retention_period = "7"
      apply_immediately       = true

      # DEBUG
      deletion_protection = false
      subnet_ids          = data.aws_subnets.private.ids
      publicly_accessible = false
      ingress_with_cidr_blocks = [
        {
          rule        = "mysql-tcp"
          cidr_blocks = "0.0.0.0/0"
        }
      ]

      dns_records = {
        "" = {
          zone_name    = local.zone_private
          private_zone = true
        }
      }

      db_parameter_group_parameters = [
        {
          name         = "connect_timeout"
          value        = 120
          apply_method = "immediate"
          }, {
          name         = "general_log"
          value        = 0
          apply_method = "immediate"
          }, {
          name         = "innodb_lock_wait_timeout"
          value        = 300
          apply_method = "immediate"
          }, {
          name         = "log_output"
          value        = "FILE"
          apply_method = "pending-reboot"
          }, {
          name         = "long_query_time"
          value        = 5
          apply_method = "immediate"
          }, {
          name         = "max_connections"
          value        = 150
          apply_method = "immediate"
          }, {
          name         = "slow_query_log"
          value        = 1
          apply_method = "immediate"
          }, {
          name         = "log_bin_trust_function_creators"
          value        = 1
          apply_method = "immediate"
        }
      ]

      # DB MANAGEMENT
      enable_db_management                    = true
      enable_db_management_logs_notifications = true
      db_management_parameters = {
        databases = [
          {
            name    = "sqldb1"
            charset = "utf8mb4"
            collate = "utf8mb4_general_ci"
          },
          {
            name    = "sqlsdb2"
            charset = "utf8mb4"
            collate = "utf8mb4_general_ci"
          }
        ],
        users = [
          {
            username = "usuario1"
            host     = "%"
            password = "password1"
            grants = [
              {
                database   = "sqldb1"
                table      = "*"
                privileges = "ALL"
              },
              {
                database   = "sqlsdb2"
                table      = "*"
                privileges = "SELECT, UPDATE"
              }
            ]
          },
          {
            username = "usuario2"
            host     = "%"
            password = "password2"
            grants = [
              {
                database   = "sqlsdb2"
                table      = "*"
                privileges = "ALL"
              }
            ]
          }
        ],
        excluded_users = ["rdsadmin", "root", "mariadb.sys", "healthcheck", "rds_superuser_role", "mysql.infoschema", "mysql.session", "mysql.sys"]
      }
    }
  }

  rds_defaults = var.rds_defaults
}
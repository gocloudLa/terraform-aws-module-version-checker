# Documentation

## Introducción

El Wrapper de Terraform para RDS simplifica la configuración del Servicio de Base de Datos Relacional en la nube de AWS. Este wrapper funciona como una plantilla predefinida, facilitando la creación y gestión de instancias de RDS al encargarse de todos los detalles técnicos.

**Features**

- [Administración de Usuarios y Bases](#administración-de-usuarios-y-bases)
- [Dump con S3](#dump-con-s3)
- [Restore con S3](#restore-con-s3)
- [DB Reset](#db-reset)
- [Registro DNS](#registro-dns)
- [Enrolamiento de Point in time Recovery](#enrolamiento-de-point-in-time-recovery)

**Diagrama** <br/>

A continuación se puede ver una imagen que muestra la totalidad de recursos que se pueden desplegar con el wrapper:

<center>![alt text](diagrams/main.png)</center>

---

## Modo de Uso

```hcl

rds_parameters = {
  ## Nombre y definición de una instancia RDS
  "00" = {
    
    ## Definiciones para la creación del motor
    engine                 = "mariadb"
    engine_version         = "10.6.14"
    instance_class         = "db.t3.micro"
    deletion_protection    = true
    publicly_accessible    = false
    
    ## Definición de subnets sobre las cuales se desplegará y accederá al motor
    ## Definido por ids
    subnet_ids             = data.aws_subnets.public.ids
    ## Definido por nombre
    # subnet_name = "${local.common_name_prefix}-db*" # Default: "${local.common_name_prefix}-private*"
    
    ## Reglas de acceso para el recurso
    ingress_with_cidr_blocks = [
      {
        rule        = "mysql-tcp"
        cidr_blocks = "172.1.0.0/16"
      }
    ]
    
    ## Definición de tamaño y tipo de storage para el motor
    allocated_storage     = 5
    max_allocated_storage = 10
    storage_type          = null
    
    ## Parametros que utilizara el motor
    parameters = [
      {
        name  = "max_connections"
        value = "150"
      }
    ]
    ## Definiciones de ventanas de mantenimiento y backup
    maintenance_window      = "Sun:04:00-Sun:06:00"
    backup_window           = "03:00-03:30"
    backup_retention_period = "7"
    apply_immediately       = false
    
    ## Habilitación y retención de servicio de performance insights
    #performance_insights_enabled           = false
    #performance_insights_retention_period  = 7
  }
}

rds_defaults = var.rds_defaults

```

<details>
<summary>Tabla de Variables</summary>

| Variable                              | Descripción de variable                                               | Tipo              | Default                                                      | Alternativas |
|---------------------------------------|-----------------------------------------------------------------------|-------------------|--------------------------------------------------------------|--------------|
| engine                                | Motor de base de datos                                                | String            | "mariadb"                                                    | "mariadb", "mysql", "oracle-ee", "postgres", "sqlserver-ee" |
| engine_version                        | Version del motor deseada                                             | String            | "10.6.14"                                                    | validar segun motor utilizado |
| instance_class                        | Tamaño del recurso                                                    | String            | "db.t3.micro"                                                | [Link](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html) |
| deletion_protection                   | Protección contra eliminación del recurso                             | Boleano           | true                                                         | true o false |
| publicly_accessible                   | Habilita el acceso desde internet                                     | Boleano           | false                                                        | true o false |
| subnet_ids                            | Listado de subnets sobre los cuales se despliega el recurso           | Lista             | []                                                           | Puede utilizarse un datasource o un listado de Subnets IDs |
| subnet_name                           | Wildcard para encontrar las subnets en donde deployar motor y lambdas | String            | `"${local.common_name_prefix}-private*"`                     | `"${local.common_name_prefix}-db*"` |
| ingress_with_cidr_blocks              | Reglas de entrada para el recurso                                     | Array de Objetos  | `[{ rule = "mysql-tcp", cidr_blocks = "172.1.0.0/16" }]`     | `[{ rule = "mysql-tcp", cidr_blocks = "X.X.X.X/32" }]` |
| allocated_storage                     | Almacenamiento mínimo de la instancia                                 | Entero            | 5                                                            | Mínimo valor, depende del motor |
| max_allocated_storage                 | Almacenamiento máximo de la instancia                                 | Entero            | 10                                                           | null o Máximo valor, según el motor |
| storage_type                          | Tipo de almacenamiento                                                | string            | null                                                         | "standard", "gp2", "gp3", "io1", depende del motor |
| parameters                            | Definición de parámetros para Parameter Group                         | Array de Objetos  | `[ {   name  = "max_connections, "value = "150" }    ]`      |  [Link](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.MariaDB.Parameters.html)  |
| maintenance_window                    | Horario de ventana de mantenimiento                                   | String            | "Sun:04:00-Sun:06:00"                                        | "Día:04:00-Día:06:00", reemplazar Día por mon, etc el mismo es en UTC |
| backup_window                         | Horario de ventana de Backup                                          | String            | "03:00-03:30"                                                | ""03:00-03:30" |
| backup_retention_period               | Retención en dias de Backups                                          | Entero            | "7"                                                          | 0 a 35 |
| apply_immediately                     | Aplica inmediatamente cambios que puedan reiniciar el motor           | Boleano           | false                                                        | true o false |
| performance_insights_enabled          | Habilitación de feature de Performance Insights                       | Boleano           | false                                                        | true o false |
| performance_insights_retention_period | Retención de informacón de feature de Performance Insights            | Entero             | 7                                                            | 7, multiplos de 30 o 365 |
| username                                              | El nombre de usuario maestro de la base de datos.                             | string             | root                        | custom username                                      |
| password                                              | La contraseña del usuario maestro generada por el recurso random password.     | string             | generada automáticamente    | custom password                                      |
| manage_master_user_password                           | Administra automáticamente la rotación de la contraseña del usuario maestro.   | bool               | false                       | true o false                                         |
| master_user_secret_kms_key_id                         | ID de la clave KMS para cifrar el secreto del usuario maestro.                 | string             | null                        | custom KMS key ID                                    |
| manage_master_user_password_rotation                  | Activa la rotación automática de la contraseña del usuario maestro.            | bool               | false                       | true o false                                         |
| master_user_password_rotate_immediately               | Rota inmediatamente la contraseña del usuario maestro.                        | bool               | null                        | true o false                                         |
| master_user_password_rotation_automatically_after_days| Número de días tras los cuales se rota automáticamente la contraseña.         | number             | null                        | número entero                                        |
| master_user_password_rotation_duration                | Duración en días de la validez de la contraseña tras la rotación.              | number             | null                        | custom duration                                      |
| master_user_password_rotation_schedule_expression     | Expresión de programación para la rotación (ejemplo, cron).                    | string             | null                        | custom schedule expression                           |
| create_db_subnet_group            | Indica si se debe crear un grupo de subredes para la base de datos.            | bool      | true                           | true o false                                         |
| db_subnet_group_name              | Nombre del grupo de subredes para la base de datos.                            | string    | `${local.common_name}-${each.key}`| custom name                                          |
| db_subnet_group_use_name_prefix   | Usa un prefijo de nombre para el grupo de subredes.                            | bool      | false                          | true o false                                         |
| db_subnet_group_description       | Descripción del grupo de subredes.                                             | string    | null                           | custom description                                   |
| db_subnet_group_tags              | Etiquetas asignadas al grupo de subredes.                                      | map       | {}                             | custom tags                                          |
| create_db_parameter_group         | Indica si se debe crear un grupo de parámetros para la base de datos.          | bool      | true                           | true o false                                         |
| parameter_group_name              | Nombre del grupo de parámetros para la base de datos.                          | string    | `${local.common_name}-${each.key}`| custom name                                          |
| parameter_group_use_name_prefix   | Usa un prefijo de nombre para el grupo de parámetros.                          | bool      | false                          | true o false                                         |
| family                            | Familia de la base de datos para el grupo de parámetros.                       | string    | mariadb10.6                    | custom family                                        |
| parameters                        | Lista de parámetros del grupo de parámetros.                                   | list      | []                             | custom parameters                                    |
| parameter_group_description       | Descripción del grupo de parámetros.                                           | string    | null                           | custom description                                   |
| db_parameter_group_tags           | Etiquetas asignadas al grupo de parámetros.                                    | map       | {}                             | custom tags                                          |
| create_db_option_group            | Indica si se debe crear un grupo de opciones para la base de datos.            | bool      | true                           | true o false                                         |
| option_group_name                 | Nombre del grupo de opciones para la base de datos.                            | string    | `${local.common_name}-${each.key}`| custom name                                          |
| option_group_use_name_prefix      | Usa un prefijo de nombre para el grupo de opciones.                            | bool      | false                          | true o false                                         |
| major_engine_version              | Versión principal del motor para el grupo de opciones.                         | string    | 10.6                           | custom engine version                                |
| options                           | Lista de opciones del grupo de opciones.                                       | list      | []                             | custom options                                       |
| option_group_description          | Descripción del grupo de opciones.                                             | string    | null                           | custom description                                   |
| option_group_timeouts             | Timeouts para las operaciones del grupo de opciones.                           | map       | {}                             | custom timeouts                                      |
| db_option_group_tags              | Etiquetas asignadas al grupo de opciones.                                      | map       | {}                             | custom tags                                          |
| option_group_skip_destroy         | Si debe evitarse la destrucción del grupo de opciones.                         | bool      | null                           | true o false                                         |
| create_db_instance                | Indica si se debe crear la instancia de base de datos.                       | bool      | true                           | true o false                                         |
| engine_lifecycle_support          | Soporte de ciclo de vida del motor de la base de datos.                      | string    | null                           | custom engine support                                |
| instance_class                    | Clase de instancia de la base de datos.                                      | string    | db.t3.micro                    | custom instance class                                |
| port                              | Puerto para la conexión a la base de datos.                                  | int       | 3306                           | custom port                                          |
| db_name                           | Nombre de la base de datos.                                                  | string    | null                           | custom db name                                       |
| vpc_security_group_ids            | Lista de IDs de grupos de seguridad del VPC.                                 | list      | `[module.security_group_rds]`     | custom security group                                |
| network_type                      | Tipo de red para la base de datos.                                           | string    | null                           | custom network type                                  |
| availability_zone                 | Zona de disponibilidad para la base de datos.                                | string    | null                           | custom availability zone                             |
| multi_az                          | Habilitar multi-AZ para alta disponibilidad.                                 | bool      | false                          | true o false                                         |
| kms_key_id                        | ID de la clave KMS para cifrado de la base de datos.                         | string    | null                           | custom KMS key ID                                    |
| ca_cert_identifier                | Identificador del certificado CA para la base de datos.                      | string    | null                           | custom CA certificate                                |
| publicly_accessible               | Indica si la base de datos es públicamente accesible.                        | bool      | false                          | true o false                                         |
| deletion_protection               | Protección contra la eliminación de la base de datos.                        | bool      | true                           | true o false                                         |
| timeouts                          | Configuración de tiempos de espera para la base de datos.                    | map       | {}                             | custom timeouts                                      |
| snapshot_identifier               | Identificador del snapshot para restaurar la base de datos.                  | string    | null                           | custom snapshot ID                                   |
| db_instance_tags                  | Etiquetas asignadas a la instancia de base de datos.                         | map       | {}                             | custom tags                                          |
| custom_iam_instance_profile       | Perfil de instancia IAM personalizado.                                       | string    | null                           | custom IAM profile                                   |
| dedicated_log_volume              | Indica si se debe crear un volumen dedicado para los logs de la base de datos.| bool      | false                          | true o false                                         |
| allocated_storage                      | Almacenamiento asignado para la base de datos.                              | int       | 5                            | custom storage size                              |
| max_allocated_storage                  | Almacenamiento máximo asignado para la base de datos.                       | int       | 10                           | custom max storage size                          |
| storage_type                           | Tipo de almacenamiento (gp2, io1, etc.).                                    | string    | null                         | custom storage type                              |
| iops                                   | Número de IOPS asignados para almacenamiento.                               | int       | null                         | custom IOPS                                      |
| storage_throughput                     | Rendimiento de almacenamiento en MB/s.                                      | int       | null                         | custom storage throughput                        |
| storage_encrypted                      | Indica si el almacenamiento está cifrado.                                   | bool      | true                         | true o false                                     |
| upgrade_storage_config                 | Configuración para actualización de almacenamiento.                         | string    | null                         | custom storage upgrade                           |
| iam_database_authentication_enabled    | Habilitar autenticación IAM para la base de datos.                          | bool      | false                        | true o false                                     |
| domain                                | Dominio al que está asociado la base de datos.                              | string    | null                         | custom domain                                    |
| domain_auth_secret_arn                 | ARN del secreto de autenticación del dominio.                               | string    | null                         | custom domain secret ARN                         |
| domain_dns_ips                         | IPs DNS asociadas al dominio.                                               | list      | null                         | custom domain DNS IPs                            |
| domain_fqdn                            | FQDN (nombre de dominio completo) del dominio.                              | string    | null                         | custom FQDN                                      |
| domain_iam_role_name                   | Nombre del rol IAM asociado al dominio.                                     | string    | null                         | custom domain IAM role                           |
| domain_ou                              | Unidad organizativa (OU) del dominio.                                       | string    | null                         | custom domain organizational unit (OU)           |
| delete_automated_backups               | Indica si se deben eliminar los backups automatizados.                      | bool      | true                         | true o false                                     |
| restore_to_point_in_time               | Restaurar a un punto específico en el tiempo.                               | string    | null                         | custom point-in-time restore                     |
| final_snapshot_identifier_prefix       | Prefijo para el identificador del snapshot final.                           | string    | null                         | custom snapshot identifier prefix                |
| skip_final_snapshot                    | Saltar la creación de snapshot final al eliminar la instancia.              | bool      | true                         | true o false                                     |
| copy_tags_to_snapshot                  | Copiar etiquetas al snapshot al crearlo.                                    | bool      | true                         | true o false                                     |
| maintenance_window                     | Ventana de mantenimiento para la instancia RDS.                             | string    | "Sun:04:00-Sun:06:00"         | custom maintenance window                        |
| allow_major_version_upgrade            | Permitir la actualización de versión mayor del motor de base de datos.      | bool      | false                        | true o false                                     |
| auto_minor_version_upgrade             | Actualización automática de versiones menores.                              | bool      | true                         | true o false                                     |
| apply_immediately                      | Aplicar los cambios inmediatamente, si es posible.                          | bool      | false                        | true o false                                     |
| create_monitoring_role                 | Crear el rol de monitoreo para RDS.                                         | bool      | true                         | true o false                                     |
| monitoring_role_arn                    | ARN del rol de monitoreo existente.                                         | string    | null                         | custom monitoring role ARN                       |
| monitoring_role_name                   | Nombre del rol de monitoreo.                                                | string    | `"${local.common_name}-rds-monitoring-${each.key}"` | custom monitoring role name                      |
| monitoring_role_use_name_prefix        | Usar prefijo para el nombre del rol de monitoreo.                           | bool      | false                        | true o false                                     |
| monitoring_role_description            | Descripción del rol de monitoreo.                                           | string    | null                         | custom monitoring role description               |
| monitoring_interval                    | Intervalo de monitoreo en segundos.                                         | int       | 0                            | custom monitoring interval                       |
| performance_insights_kms_key_id        | KMS Key ID para Performance Insights.                                       | string    | null                         | custom KMS Key ID                                |
| create_cloudwatch_log_group            | Crear grupo de logs en CloudWatch.                                          | bool      | false                        | true o false                                     |
| enabled_cloudwatch_logs_exports        | Exportar logs a CloudWatch.                                                 | list      | []                           | custom CloudWatch logs exports                   |
| cloudwatch_log_group_retention_in_days | Retención de logs en CloudWatch (días).                                     | int       | 7                            | custom retention period                          |
| cloudwatch_log_group_kms_key_id        | KMS Key ID para el grupo de logs en CloudWatch.                             | string    | null                         | custom KMS Key ID                                |
| monitoring_role_permissions_boundary   | Límite de permisos para el rol de monitoreo.                                | string    | null                         | custom permissions boundary                      |
| cloudwatch_log_group_skip_destroy      | Omitir la destrucción del grupo de logs en CloudWatch.                      | bool      | null                         | true o false                                     |
| cloudwatch_log_group_class             | Clase del grupo de logs en CloudWatch.                                      | string    | null                         | custom log group class                           |
| license_model                          | Modelo de licencia para bases de datos.                                     | string    | null                         | custom license model                             |
| timezone                               | Zona horaria para bases de datos SQL Server.                                | string    | null                         | custom timezone                                  |
| replicate_source_db          | Nombre de la instancia de origen para la replicación.                  | string  | null                       | custom source DB for replication                    |
| replica_mode                 | Modo de réplica para la instancia de base de datos.                    | string  | null                       | custom replica mode                                 |
| character_set_name           | Nombre del conjunto de caracteres de la base de datos.                 | string  | null                       | custom character set name                           |
| nchar_character_set_name     | Nombre del conjunto de caracteres NCHAR de la base de datos.           | string  | null                       | custom NCHAR character set name                     |
| s3_import                    | Configuración de importación de datos desde S3 para MySQL.             | string  | null                       | custom S3 import configuration                      |
| db_instance_role_associations| Asociaciones de roles de instancia de base de datos (por ejemplo, IAM).| map     | {}                         | custom DB instance role associations                |
</details>

:::danger alerta 
Reinicia el motor durante cambios en el parameter group<br/>
apply_immediately       = true
:::
:::warning precaución 
Expone el recurso a internet <br/>
publicly_accessible    = true 
:::
:::info 
Habilita el crecimiento del storage sin limite<br/>
max_allocated_storage = null  <br/> <br/>
En caso de necesitar ajustar parámetros del paramter group para motores distintos a MySQL o MariaDB se recomienda hacerlo desde la consola de administración de AWS
:::
---

## Modo de Uso Avanzado

### Administración de Usuarios y Bases

Despliega función lambda, que administrar el alta y modificación de *Usuarios*, *Bases de datos* y sus accesos a los mismos.
Los credenciales de los accesos quedarán almacenados en un parámetro de **Parameter Store**. <br/>
Envia notificaciones de lo realizado.
No realiza la baja de las bases de datos, ni de los usuarios, los últimos permanecerán sin permisos sobre los recursos. 
<details>
<summary>Código MySQL / MariaDB</summary>

```hcl
rds_parameters = {
  "mysql" = {
    ...
    enable_db_management                    = true
    enable_db_management_logs_notifications = true
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
    ...
  }
}
```

</details>
<br/>
<details>
<summary>Código PostgreSQL</summary>

```hcl
rds_parameters = {
  "postgresql" = {
    ...
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
    ...
  }
}
```

</details>

### Dump con S3

Este módulo crea los recursos necesarios para generar un dump SQL y almacenarlo en un bucket de S3, junto con scripts de limpieza para la base de datos. <br/> Soporta los motores de base de datos **MySQL**, **MariaDB** y **PostgreSQL**
<details>
<summary>Código</summary>

```hcl
rds_parameters = {
  "00" = {
    ...
    enable_db_dump_create = true
    db_dump_create_local_path_custom_scripts = "${path.module}/content/custom_sql"
    db_dump_create_schedule_expression = "cron(0 * * * ? *)"
    db_dump_create_db_name = "demo"
    db_dump_create_retention_in_days = 7
    db_dump_create_s3_arn_permission_accounts = [
      "arn:aws:iam::xxxxxxxxxxx:root", # demo.la-dev
      "arn:aws:iam::xxxxxxxxxxx:root", # demo.la-stg
    ]
    ...
  }
}
```
</details>

### Restore con S3

Este módulo crea los recursos necesarios para realizar una restauración a partir de un dump SQL almacenado en un bucket y ejecutar los scripts de limpieza necesarios. <br/> Soporta los motores de base de datos **MySQL**, **MariaDB** y **PostgreSQL**
<details>
<summary>Código</summary>

```hcl
enable_db_dump_restore = true
db_dump_restore_s3_bucket_name = "demo-l04-core-00-db-dump-create"
db_dump_restore_db_name = "demo"
```
</details>

:::warning precaución 
Posibilita sobreescribir los datos de una base dentro del motor<br/>
:::

### DB Reset

Este módulo elimina la base de datos y la vuelve a crear, eliminando todos los datos. Esta pensada para ser utilizada en entornos de desarrollo. <br/> Soporta los motores de base de datos **MySQL**, **MariaDB** y **PostgreSQL**.
<details>
<summary>Código</summary>

```hcl
enable_db_reset = true
```
</details>

:::danger alerta 
Realiza un DROP/CREATE de una base dentro del motor<br/>
:::

### Registro DNS

Da de alta un registro DNS de tipo CNAME en una hosted zone de Route53 que este presente dentro de la cuenta, la misma puede ser publica o privada dependiendo del tipo de visibilidad del registro que se desee.
<details>
<summary>Código</summary>

```hcl
dns_records = {
  "" = {
    # zone_name    = local.zone_private
    # private_zone = true
    zone_name    = local.zone_public
    private_zone = false
  }
}
```
</details>

### Enrolamiento de Point in time Recovery

Este tag permite al recurso agregarse a una política de backup de tipo Point in Time Recovery. Requiere tener desplegada la politica con AWS Backups y el tag a utilizar.
<details>
<summary>Código</summary>

```hcl
tags = { ptr-14d = "true" }
```
</details>

import os
import boto3
import json
import psycopg2
import re
import logging  

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Global variable to store logs
log_messages = []

session = boto3.session.Session()
client = session.client(
  service_name='secretsmanager',
  region_name = os.environ['AWS_REGION']
)

def get_secret():
  # Your secret's name and region
  ## Retrieve secret
  get_secret_value_response = client.get_secret_value(
      SecretId=os.environ['SECRET_NAME']
  )
  #Raw Response
  tmp_secret = get_secret_value_response['SecretString']
  json_object = json.loads(tmp_secret)

  #rds settings
  secret["host"]  = json_object['host']
  secret["username"] = json_object['username']
  secret["password"] = json_object['password']
  secret["port"] = json_object['port']

  return secret


def get_parameter_value():
  try:
    # Create a boto3 client for SSM in the specified region
    ssm_client = boto3.client(
      service_name='ssm',
      region_name=os.environ['AWS_REGION']
    )

    # Use the client to get the parameter value
    response = ssm_client.get_parameter(
      Name=os.environ['PARAMETER_NAME'],
      WithDecryption=True  # Decrypts the value if the parameter is encrypted
    )

    # Extract the parameter value from the response
    parameter_value = json.loads(response['Parameter']['Value'])

    return parameter_value

  except NoCredentialsError:
    logging.error("AWS credentials are not configured.")
    return None
  except Exception as e:
    logging.error(f"An error occurred: {e}")
    return None

def log_query(query):
  pattern = r"WITH PASSWORD '[^']*'"
  query = re.sub(pattern, "WITH PASSWORD 'xxxxxxxxxxxx'", query)
  log_messages.append(f"Executing query: {query}")


def connect_to_postgresql(dbname=None):
    try:
        if dbname:
            conn = psycopg2.connect(dbname=dbname, **db_config)
        else:
            conn = psycopg2.connect(dbname='postgres', **db_config)
        return conn
    except psycopg2.Error as err:
        logging.error(f"Database connection error: {err}")
        return None


def execute_query(cursor, query):
    log_query(query)
    cursor.execute(query)

def database_exists(cursor, dbname):
    cursor.execute(f"SELECT 1 FROM pg_database WHERE datname='{dbname}'")
    return cursor.fetchone() is not None

def create_database(data):
    conn = connect_to_postgresql()
    if conn:
        conn.autocommit = True
        cursor = conn.cursor()

        for db_info in data['databases']:
            database_name = db_info['name']
            if not database_exists(cursor, database_name):
                query = f"CREATE DATABASE {database_name}"
                execute_query(cursor, query)
            else :
                log_messages.append(f"CREATE DATABASE {database_name} (existing/skip)")

        conn.commit()
        conn.close()

def create_schemas(data):
    for db_info in data['databases']:
        database_name = db_info['name']
        conn = connect_to_postgresql(dbname=database_name)
        if conn:
            conn.autocommit = True
            cursor = conn.cursor()

            for schema in db_info.get('schemas', []):
                schema_name = schema['name']
                schema_query = f"CREATE SCHEMA IF NOT EXISTS {schema_name}"
                execute_query(cursor, schema_query)

            conn.commit()
            cursor.close()
            conn.close()

def user_exists(cursor, username):
    cursor.execute(f"SELECT 1 FROM pg_roles WHERE rolname='{username}'")
    return cursor.fetchone() is not None

def create_users(data):
    conn = connect_to_postgresql()
    if conn:
        cursor = conn.cursor()

        for user_info in data['users']:
            username = user_info['username']
            password = user_info['password']
            # grants = user_info.get('grants', [])

            if not user_exists(cursor, username):
                query_user = f"CREATE USER {username} WITH PASSWORD '{password}'"
                execute_query(cursor, query_user)
            else :
                log_messages.append(f"CREATE USER {username} (existing/skip)")

            query_user = f"ALTER USER {username} WITH PASSWORD '{password}'"
            execute_query(cursor, query_user)
        conn.commit()
        conn.close()

def create_roles(data):
    conn = connect_to_postgresql()
    if conn:
        cursor = conn.cursor()

        for role_info in data.get('roles', []):
            rolename = role_info['rolename']

            if not user_exists(cursor, rolename):
                query_role = f"CREATE ROLE {rolename}"
                execute_query(cursor, query_role)
            else :
                log_messages.append(f"CREATE ROLE {rolename} (existing/skip)")

        conn.commit()
        conn.close()

def set_database_owner(data):
    conn = connect_to_postgresql()
    if conn:
        cursor = conn.cursor()
        try:
            for db_info in data.get('databases', []):
                database_name = db_info['name']
                owner = db_info.get('owner', 'postgres')  # Propietario por defecto

                query = f"ALTER DATABASE {database_name} OWNER TO {owner}"
                execute_query(cursor, query)

            # logging.info("Database ownership setup completed.")
        finally:
            conn.commit()
            cursor.close()
            conn.close()

def set_schema_owner(data):
    for db_info in data.get('databases', []):
        database_name = db_info['name']
        conn = connect_to_postgresql(dbname=database_name)
        if conn:
            conn.autocommit = True
            cursor = conn.cursor()

            for schema in db_info.get('schemas', []):
                schema_name = schema['name']
                schema_owner = schema.get('owner')
                if schema_owner is not None:
                    query = f"ALTER SCHEMA {schema_name} OWNER TO {schema_owner}"
                    execute_query(cursor, query)
                    # logging.info(f"Changed owner of schema '{schema_name}' in database '{database_name}' to '{schema_owner}'")
            conn.commit()
            cursor.close()
            conn.close()
    # logging.info("Schema ownership setup completed.")


def update_users_and_grants(data):

    # BORRO USUARIOS QUE NO EXISTAN MAS
    conn = connect_to_postgresql()
    if conn:
        cursor = conn.cursor()
        # Get the list of PostgreSQL users
        cursor.execute("SELECT rolname FROM pg_roles")
        pg_users = [user[0] for user in cursor.fetchall()]

        for pg_user in pg_users:
            if (pg_user not in data.get('excluded_users', []) and 
                    pg_user not in [user_info['username'] for user_info in data['users']] and
                    pg_user not in [role_info['rolename'] for role_info in data.get('roles', [])] and
                    not pg_user.startswith('pg_') and 
                    not pg_user.startswith('rds')):
                query_drop = f"DROP USER IF EXISTS {pg_user}"
                execute_query(cursor, query_drop)

        conn.commit()
        conn.close()

    # BORRO PRIVILEGIOS DE USUARIOS EXISTENTES
    for db_info in data.get('databases', []):
        database_name = db_info['name']
        conn = connect_to_postgresql(dbname=database_name)
        if conn:
            cursor = conn.cursor()

            for user_info in data['users']:
                username = user_info['username']
                grants = user_info.get('grants', [])

                query_revoke = f"REVOKE ALL PRIVILEGES ON DATABASE {database_name} FROM {username}"
                cursor.execute(query_revoke)

                # Revoke all privileges before granting new ones
                for schema in get_schemas(cursor):
                    query_revoke = f"REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA {schema} FROM {username}"
                    cursor.execute(query_revoke)
                    # execute_query(cursor, query_revoke) # Disable Logging
                    query_revoke_default = f"ALTER DEFAULT PRIVILEGES IN SCHEMA {schema} REVOKE ALL ON TABLES FROM {username}"
                    cursor.execute(query_revoke_default)
                    # execute_query(cursor, query_revoke_default) # Disable Logging

    # HAGO GRANTS ESPECIFICOS DE USUARIOS
    for user_info in data['users']:
        username = user_info['username']
        grants = user_info.get('grants', [])

        for grant_info in grants:
            privileges = grant_info.get('privileges')
            schema     = grant_info.get('schema', 'public')
            database   = grant_info.get('database')
            options    = grant_info.get('options', '')
            table      = grant_info.get('table')

            conn = connect_to_postgresql(dbname=database)
            if conn:
                cursor = conn.cursor()
                if table == '*':
                    grant_query = f"GRANT {privileges} ON ALL TABLES IN SCHEMA {schema} TO {username} {options}"
                elif table :
                    grant_query = f"GRANT {privileges} ON TABLE {schema}.{table} TO {username} {options}"
                elif database :
                    grant_query = f"GRANT {privileges} ON DATABASE {database} TO {username} {options}"
                else:
                    grant_query = f"GRANT {privileges} TO {username} {options}"

                execute_query(cursor, grant_query)

                if table == '*':
                  # Grant default privileges for future tables
                  grant_default_query = f"ALTER DEFAULT PRIVILEGES IN SCHEMA {schema} GRANT {privileges} ON TABLES TO {username}"
                  execute_query(cursor, grant_default_query)

                conn.commit()
                cursor.close()
                conn.close()


def get_schemas(cursor):
    cursor.execute("SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('pg_catalog', 'information_schema')")
    return [row[0] for row in cursor.fetchall()]

# Configuration parameters

secret = {}
secret = get_secret()

# MySQL database configuration

db_config = {
  'user': secret["username"],
  'password': secret["password"],
  'host': secret["host"],
}

def lambda_handler(event, context):


  # Reference the global variable
  global log_messages  
  # Reset log messages at the beginning of each execution
  log_messages = []

  # print(event)
  # print(context)

  try:

    # OPCION LEER DESDE SSM
    data = get_parameter_value()

    # Create databases
    create_database(data)

    create_schemas(data)

    # Create roles
    create_roles(data)

    # Create users and assign privileges
    create_users(data)


    set_database_owner(data)
    set_schema_owner(data)

    # Delete missing users & recreate grants
    update_users_and_grants(data)
    

  except Exception as e:
    # Log the exception
    logger.error(f"An error occurred: {e}")

  # Print all log messages at the end of execution or upon exception
  log_event = '\n'.join(log_messages)
  logger.info(log_event)
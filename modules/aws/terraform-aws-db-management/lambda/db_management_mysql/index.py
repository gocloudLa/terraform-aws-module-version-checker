import os
import boto3
import json
import pymysql
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
  pattern = r"IDENTIFIED BY '[^']*'"
  query = re.sub(pattern, "IDENTIFIED BY 'xxxxxxxxxxxx'", query)
  log_messages.append(f"Executing query: {query}")

def connect_to_mysql():
  try:
    conn = pymysql.connect(**db_config)
    return conn
  except pymysql.Error as err:
    logging.error(f"Database connection error: {err}")
    return None

def execute_query(cursor, query):
  log_query(query)
  cursor.execute(query)

def create_database(data):
  conn = connect_to_mysql()
  if conn:
    cursor = conn.cursor()

    for db_info in data['databases']:
      database_name = db_info['name']
      charset = db_info.get('charset', 'utf8mb4')
      collate = db_info.get('collate', 'utf8mb4_general_ci')

      query = f"CREATE DATABASE IF NOT EXISTS {database_name} CHARACTER SET {charset} COLLATE {collate}"
      execute_query(cursor, query)

    conn.commit()
    conn.close()

# TODO ADAPTAR EL CODIGO PARA ADMITIR TRYCATCH COMO POR EJEMPLO
# def create_database(data):
#   conn = connect_to_mysql() 
#   if conn:
#     try:
#       with conn.cursor() as cursor:
#         for db_info in data['databases']:
#           # Asegúrate de que 'name' esté presente en db_info
#           database_name = db_info.get('name')
#           if database_name is None:
#             raise ValueError("Missing 'name' in database info.")

#           charset = db_info.get('charset', 'utf8mb4')
#           collate = db_info.get('collate', 'utf8mb4_general_ci')

#           query = f"CREATE DATABASE IF NOT EXISTS {database_name} CHARACTER SET {charset} COLLATE {collate}"
#           execute_query(cursor, query)
#       conn.commit()
#     except (pymysql.MySQLError, pymysql.ProgrammingError, ValueError) as err:
#       logging.error(f"Error creating database: {err}")
#     finally:
#       conn.close()

def create_users(data):
  conn = connect_to_mysql()
  if conn:
    cursor = conn.cursor()

    for user_info in data['users']:
      username = user_info['username']
      host = user_info['host']
      password = user_info['password']
      grants = user_info.get('grants', [])

      query_user = f"CREATE USER IF NOT EXISTS '{username}'@'{host}' IDENTIFIED BY '{password}'"
      execute_query(cursor, query_user)

    query_flush = "FLUSH PRIVILEGES"
    execute_query(cursor, query_flush)

    conn.commit()
    conn.close()

def update_users_and_grants(data):
  conn = connect_to_mysql()
  if conn:
    cursor = conn.cursor()

    # Get the list of MySQL users in user@host format
    cursor.execute("SELECT CONCAT(User, '@', Host) FROM mysql.user")
    mysql_users = [user[0] for user in cursor.fetchall()]

    for mysql_user in mysql_users:
      user, host = mysql_user.split('@')
      if user not in data.get('excluded_users', []) and mysql_user not in [f"{user_info['username']}@{user_info['host']}" for user_info in data['users']]:
        query_drop = f"DROP USER IF EXISTS '{user}'@'{host}'"
        execute_query(cursor, query_drop)

    for user_info in data['users']:
      username = user_info['username']
      host = user_info['host']
      existing_grants = []

      cursor.execute(f"SHOW GRANTS FOR '{username}'@'{host}'")
      for grant in cursor.fetchall():
        existing_grants.append(grant[0])

      # Revoke all privileges before granting new ones
      query_revoke = f"REVOKE ALL PRIVILEGES, GRANT OPTION FROM '{username}'@'{host}'"
      execute_query(cursor, query_revoke)

      for grant_info in user_info.get('grants', []):
        grant = f"GRANT {grant_info['privileges']} ON {grant_info['database']}.{grant_info['table']} TO '{username}'@'{host}'"
        if grant not in existing_grants:
          execute_query(cursor, grant)

    query_flush = "FLUSH PRIVILEGES"
    execute_query(cursor, query_flush)

    conn.commit()
    conn.close()

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
    # OPCION LEER DESDE JSON
    # with open('mysql_setup.json', 'r') as file:
    #   data = json.load(file)
    # OPCION LEER DESDE EVENT
    # data = event

    # OPCION LEER DESDE SSM
    data = get_parameter_value()

    # Create databases
    create_database(data)

    # Create users and assign privileges
    create_users(data)

    # Delete missing users & recreate grants
    update_users_and_grants(data)
    

  except Exception as e:
    # Log the exception
    logger.error(f"An error occurred: {e}")

  # Print all log messages at the end of execution or upon exception
  log_event = '\n'.join(log_messages)
  logger.info(log_event)
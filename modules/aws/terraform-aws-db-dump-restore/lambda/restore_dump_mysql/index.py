import os
import boto3
import botocore
import json
import subprocess

session = boto3.session.Session()
client = session.client(
  service_name='secretsmanager',
  region_name=os.environ['AWS_REGION']
)

def get_secret(event, context, secret):
  # Your secret's name and region

  ## Retrieve secret
  get_secret_value_response = client.get_secret_value(
    SecretId=os.environ['SECRET_NAME']
  )
  # Raw Response
  tmp_secret = get_secret_value_response['SecretString']
  json_object = json.loads(tmp_secret)

  # rds settings
  secret["host"] = json_object['host']
  secret["username"] = json_object['username']
  secret["password"] = json_object['password']
  secret["port"] = json_object['port']

  return secret

def lambda_handler(event, context):
  s3_client = boto3.client('s3')
  s3_resource = boto3.resource('s3')

  # Set the path to the executable scripts in the AWS Lambda environment.
  os.environ['PATH'] += ':/opt/bin'
  os.environ['LD_LIBRARY_PATH'] = '/opt/lib:' + os.environ.get('LD_LIBRARY_PATH', '')

  # Configuration parameters
  bucket_name = os.environ['BUCKET_NAME']
  bucket_backup_file = os.environ['BUCKET_BACKUP_FILE']
  bucket_custom_scripts_path = os.environ['BUCKET_CUSTOM_SCRIPTS_PATH']
  db_name = os.environ['DB_NAME']

  try:
    secret = {}
    secret = get_secret(event,context,secret)

    # Download backup file to s3
    backup_local_path = "/tmp/latest_backup.sql"
    s3_client.download_file( bucket_name, bucket_backup_file , backup_local_path )
    print("file downloaded: "+ bucket_backup_file )

    # Download custom_scripts files to s3
    custom_scripts_local_path = "/tmp/custom_scripts/"
    os.makedirs(os.path.dirname(custom_scripts_local_path))
    bucket = s3_resource.Bucket(bucket_name)
    for obj in bucket.objects.filter(Prefix = bucket_custom_scripts_path):
      local_file_path = custom_scripts_local_path+os.path.basename(obj.key)
      bucket.download_file(obj.key, local_file_path)
      print("file downloaded: "+local_file_path )

    mysql_command = "/tmp/mysql"
    subprocess.check_call("cp /opt/bin/mysql /tmp/mysql && chmod 755 /tmp/mysql", shell=True)
    sql_connect = f"{mysql_command} -h {secret['host']} -u {secret['username']} -p{secret['password']}"

    # Drop database
    subprocess.check_call(f"{sql_connect} -e \"DROP DATABASE IF EXISTS {db_name};\"", shell=True)
    print("Database dropped")

    # Create database
    subprocess.check_call(f"{sql_connect} -e \"CREATE DATABASE {db_name};\"", shell=True)
    print("Database created")

    # Restore database
    restore_cmd = f"{sql_connect} {db_name} < {backup_local_path}"
    subprocess.check_call(restore_cmd, shell=True)
    print("Backup restored")

    # Execute custom scripts
    if len(os.listdir(custom_scripts_local_path)) > 0 :
      sql_execute_scripts_command = f"cat {custom_scripts_local_path}*.sql | {sql_connect} {db_name}"
      subprocess.check_call(sql_execute_scripts_command, shell=True)
      print("Custom scripts executed")

    return {
      'statusCode': 200,
      'body': 'Restore: '+ bucket_backup_file + ' creado'
    }   

  except botocore.exceptions.EndpointConnectionError as e:
    print(f"Error de conexión: {str(e)}")
    error_message = str(e)
  except botocore.exceptions.ConnectTimeoutError as e:
    print(f"Timeout de conexión: {str(e)}")
    error_message = str(e)
  except botocore.exceptions.ClientError as e:
    print(f"Error en la llamada a la API: {str(e)}")
    error_message = str(e)
  except subprocess.CalledProcessError as e:
    print(f"Error ejecutando comando: {str(e)}")
    error_message = str(e)
  except Exception as e:
    print(f"Error general: {str(e)}")
    error_message = str(e)

  return {
    'statusCode': 500,
    'body': 'Error al restaurar el backup: ' + error_message
  }
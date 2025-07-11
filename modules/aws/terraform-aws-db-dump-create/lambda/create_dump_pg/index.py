import os
import boto3
import botocore
import json
import subprocess
import datetime

session = boto3.session.Session()
client = session.client(
  service_name='secretsmanager',
  region_name=os.environ['AWS_REGION']
)

def get_secret(event, context, secret):
  # Your secret's name and region

  # Retrieve secret
  get_secret_value_response = client.get_secret_value(
    SecretId=os.environ['SECRET_NAME']
  )
	#Raw Response
  tmp_secret = get_secret_value_response['SecretString']
  json_object = json.loads(tmp_secret)

	#rds settings
  secret["host"] = json_object['host']
  secret["username"] = json_object['username']
  secret["password"] = json_object['password']
  secret["port"] = json_object['port']
  return secret

def lambda_handler(event, context):
  s3_client = boto3.client('s3')

  # For the db password
  env = os.environ.copy()

  # Set the path to the executable scripts in the AWS Lambda environment.
  os.environ['PATH'] = os.environ['PATH'] + ':' + '/opt/bin'
  os.environ['LD_LIBRARY_PATH'] = '/opt/lib:' + os.environ.get('LD_LIBRARY_PATH', '')
	
	# Configuration parameters
  bucket_name = os.environ['BUCKET_NAME']
  backup_latest_name = os.environ['BACKUP_LATEST_NAME']
  backup_history_path = os.environ['BACKUP_HISTORY_PATH']
  db_name = os.environ['DB_NAME']

  try:
    secret = {}
    secret = get_secret(event, context, secret)

    now_gmt_minus3 = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-3)))
    current_datetime = now_gmt_minus3.strftime("%Y-%m-%d_%H-%M")
    print("datetime: " + current_datetime)
    backup_history_name = current_datetime + ".sql"
    backup_local_path = "/tmp/" + backup_history_name

    # Set PostgreSQL password en variable de entorno
    env["PGPASSWORD"] = secret["password"]

    # Copy pg_dump and set permissions
    copy_cmd = "cp /opt/bin/pg_dump /tmp/pg_dump && chmod 755 /tmp/pg_dump"
    subprocess.run(copy_cmd, shell=True, check=True)

    # dump db
    pg_dump_command = f"/tmp/pg_dump -h {secret['host']} -p {secret['port']} -U {secret['username']} -F p {db_name} -f {backup_local_path}"
    result = subprocess.run(pg_dump_command, shell=True, capture_output=True, text=True, env=env)
    if result.returncode != 0:
      print("STDOUT:", result.stdout)
      print("STDERR:", result.stderr)
      raise Exception(f"pg_dump failed with return code {result.returncode}")

    print("dump created: " + backup_local_path)

    # Subir a S3
    backup_upload_history_path = backup_history_path + backup_history_name
    backup_latest_path = backup_latest_name
    s3_client.upload_file(backup_local_path, bucket_name, backup_upload_history_path)
    s3_client.upload_file(backup_local_path, bucket_name, backup_latest_path)
    print("file upload: " + backup_upload_history_path + " to bucket " + bucket_name)
    print("file upload: " + backup_latest_path + " to bucket " + bucket_name)

    return {
      'statusCode': 200,
      'body': 'Backups: ' + backup_upload_history_path + ' y: ' + backup_latest_path + ' creados'
    }

  except botocore.exceptions.EndpointConnectionError as e:
    print(f"Error de conexión: {str(e)}")
    error_message = str(e)
  except botocore.exceptions.ConnectTimeoutError as e:
    print(f"Timeout de conexión: {str(e)}")
    error_message = str(e)
  except botocore.exceptions.ClientError as e:
    print(f"Se produjo un error al realizar la llamada a la API: {str(e)}")
    error_message = str(e)
  except Exception as e:
    print(f"An error occurred while creating the backup: {str(e)}")
    error_message = str(e)

  return {
    'statusCode': 500,
    'body': 'Error al crear el backup: ' + error_message
  }

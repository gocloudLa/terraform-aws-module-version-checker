import os
import sys
import logging
import boto3
import json
import pymysql
  
logger = logging.getLogger()
logger.setLevel(logging.INFO)
session = boto3.session.Session()
client = session.client(
    service_name='secretsmanager',
    region_name = os.environ['AWS_REGION']
)

def get_secret(event, context, secret):
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
    secret["db_name"] = event['db_name']
    
    return secret

def get_connection(secret):
    
    try:
        conn = pymysql.connect(host=secret["host"], user=secret["username"], passwd=secret["password"], connect_timeout=5)
    except pymysql.MySQLError as e:
        logger.error("ERROR: Unexpected error: Could not connect to MySQL instance.")
        logger.error(e)
        sys.exit()
    
    logger.info("SUCCESS: Connection to RDS MySQL instance succeeded")
    
    return conn
    
def handler(event, context):

    """
    This function re-creates a Database for MySQL in a RDS instance
    """
    secret = {}
    secret = get_secret (event,context,secret)
    conn = get_connection (secret)
    
    with conn.cursor() as cur:
        try:
            cur.execute("DROP DATABASE %s;" %(event['db_name']))
            conn.commit()
        except pymysql.MySQLError as e:
            logger.error("ERROR: Unexpected error: Could not delete database %s." %(event['db_name']))
            logger.error(e)
        try:
            cur.execute("CREATE DATABASE %s;" %(event['db_name']))
            conn.commit()
        except pymysql.MySQLError as e:
            logger.error("ERROR: Unexpected error: Could not create database %s." %(event['db_name']))
            logger.error(e)
    
    return "The database %s was succesfully re-created" %(event['db_name'])
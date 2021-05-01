import json
import os
import boto3
from datetime import datetime
from config import configuration
from boto3.dynamodb.conditions import Key
from decimal import *

# Creating dynamo client and table resource
ddb = boto3.resource('dynamodb')
table = ddb.Table(os.environ['HITS_TABLE_NAME'])

#function to serialize decimal integers
def handle_decimal_type(obj):
  if isinstance(obj, Decimal):
      if float(obj).is_integer():
         return int(obj)
      else:
         return float(obj)
  raise TypeError

# Function to return time in milliseconds
def unix_time_millis(dt):
    epoch = datetime.utcfromtimestamp(0)
    return (dt - epoch).total_seconds() * 1000.0

# Function to scan dynam and get latest x items
def scan_last_x_items(table_client, limit_number):
    try:
        response = table_client.scan(
            TableName=os.environ['HITS_TABLE_NAME'],
            IndexName='millisec_epoch_time_stamp',
            Select='ALL_ATTRIBUTES',
        )
        key_name = 'last_' + str(limit_number) + '_requests'
        # de-serialize decimal values
        items = json.dumps(response['Items'],default = handle_decimal_type)
        # sort based on millisec_epoch_time_stamp 
        sorted_items = sorted(json.loads(items), key=lambda k: k['millisec_epoch_time_stamp'],reverse=True)
        # get subsit of items required
        return_items =  sorted_items[:limit_number]
        return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': json.dumps({ 
                    key_name: return_items
                })
        }
    except Exception as e:
        print(e)

# Function to update the dynamo db with the path, time_stamp,body and get parameters
def update_item_in_dynamo(table_client, path_string, milliseconds_epoch, timestamp_string, body, http_method,  query_string_parameters=None):
    try:
        table_client.update_item(
                Key={'path': path_string,
                'millisec_epoch_time_stamp': milliseconds_epoch,
                },
                UpdateExpression="SET body = :b, queryStringParameters=:q, http_method=:h, time_stamp=:t",
                ExpressionAttributeValues={
                    ":b": body,
                    ":q": query_string_parameters,
                    ":h": http_method,
                    ":t": timestamp_string
                }

            )
    except Exception as e:
        print(e)

# Compse respone json to return to user
def response_json(message, time_stamp):
    return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({ 
                "Message": message,
                "time_stamp": time_stamp
             })
        }

def check_if_parameter_exists(param,payload=None):
    if payload: # checking if parameters is sent in request
        # checking case insensitive for last
        payload_lower_case = { k.lower():v for k,v in payload.items() }
        if param in payload_lower_case:
            return payload_lower_case[param]

# Function to check if name or login in request and then compose message
def compose_message(payload, path):
    # compose the message if there a name in request
    if check_if_parameter_exists('name',payload) or check_if_parameter_exists('login',payload):
        name = check_if_parameter_exists('name',payload) if check_if_parameter_exists('name',payload) else check_if_parameter_exists('login',payload) 
        return 'Hello ' + name + ', You have hit location: ' + path + ' !'
    else:
        return 'Hello , You have hit location: ' + path + ' !'

def handler(event, context):
    # logging request to cloudtrail for debugging only if configruration end is dev
    if configuration["env"] == "dev":
        print('request: {}'.format(json.dumps(event)))
    path = event['path']
    http_method = event['httpMethod']
    body = event['body']
    time_stamp=datetime.now().strftime("%Y-%m-%d-%H:%M:%S")
    milliseconds_epoch = int(unix_time_millis(datetime.now()))
    if event['httpMethod'] == 'GET':
        payload = event['queryStringParameters']
        # convert json to string to insert in dynamo
        query_string_parameters = json.dumps(payload)
        if check_if_parameter_exists('last',payload):
            return scan_last_x_items(table,int(check_if_parameter_exists('last',payload)))
        else:
            update_item_in_dynamo(table, event['path'], milliseconds_epoch, time_stamp, body, http_method, query_string_parameters)
            message = compose_message(payload,path)
            return response_json(message,time_stamp)     
    elif event['httpMethod'] == 'POST':
        payload = json.loads(body)  # convert string to json
        message = compose_message(payload,path)
        if check_if_parameter_exists('last',payload):
            return scan_last_x_items(table,int(check_if_parameter_exists('last',payload)))
        else:
            update_item_in_dynamo(table, event['path'], milliseconds_epoch, time_stamp, body, http_method)
            return response_json(message,time_stamp)
        

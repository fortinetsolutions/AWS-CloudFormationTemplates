import boto3
import botocore

import logging

from .const import *

"""
if DATASTORE == "DynamoDB":
    dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
    table = dynamodb.Table(TABLE_NAME)
elif DATASTORE == "S3":
    boto_session = boto3.Session()
    s3 = boto_session.resource('s3')
s3_client = boto3.client('s3')
"""

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


def process_message(event, data):
    logger.debug("process_message: event = %s, data = %s", event, data)
    return "Message Received"


def process_scheduled(event, data):
    logger.debug("process_scheduled: event = %s, data = %s", event, data)
    return "Message Received"

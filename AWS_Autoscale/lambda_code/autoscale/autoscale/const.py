
import logging

STATUS_OK = 200
STATUS_NOT_OK = 100

#
# DynamoDB attributes for creating the DB
#
attribute_definitions = [{'AttributeName': 'Type', 'AttributeType': 'S'},
                         {'AttributeName': 'TypeId', 'AttributeType': 'S'}]

TYPE_AUTOSCALE_GROUP = "0000"
TYPE_INSTANCE_ID = "0010"
TYPE_ENI_ID = "0020"
TYPE_ROUTETABLE_ID = "0030"
TYPE_BYOL_LICENSE = "0040"
TYPE_SUBSCRIPTION_REQUEST = "0050"

schema = [{'AttributeName': 'Type', 'KeyType': 'HASH'},
          {'AttributeName': 'TypeId', 'KeyType': 'RANGE'}]
provisioned_throughput = {'ReadCapacityUnits': 5, 'WriteCapacityUnits': 5}


logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


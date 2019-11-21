import json
try:
    import urllib3 as urllib
except ImportError:
    import urllib

from urllib.request import urlopen


from urllib.parse import urlparse

import re
import boto3
import random

import time

from django.conf import settings
from django.utils import timezone
from django.core.cache import caches
from boto3.dynamodb.conditions import Key
from django.utils.encoding import smart_str

from django.http import HttpResponseBadRequest, HttpResponse, Http404
from django.views.decorators.csrf import csrf_exempt

from .AutoScaleGroup import AutoScaleGroup
from .Fortigate import Fortigate

from .const import *
from .signals import *
from .scheduled import *
from .utils import *


VITAL_NOTIFICATION_FIELDS = [
    'Type', 'Message', 'Timestamp', 'Signature',
    'SignatureVersion', 'TopicArn', 'MessageId',
    'SigningCertURL'
]

ALLOWED_TYPES = [
    'Notification', 'SubscriptionConfirmation', 'UnsubscribeConfirmation'
]
STATUS_OK = 200


def respond_to_subscription_request(request):
    logger.debug("subscription request(): method = %s" % request.method)
    if request.method != 'POST':
        raise Http404

    # If necessary, check that the topic is correct
    if hasattr(settings, 'FGTSCEVT_TOPIC_ARN'):
        # Confirm that the proper topic header was sent
        if 'HTTP_X_AMZ_SNS_TOPIC_ARN' not in request.META:
            return HttpResponseBadRequest('No TopicArn Header')
        #
        # Check to see if the topic is in the settings
        # Because you can have bounces and complaints coming from multiple
        # topics, FGTSCEVT_TOPIC_ARN is a list
        #
        if not request.META['HTTP_X_AMZ_SNS_TOPIC_ARN'] in settings.FGTSCEVT_TOPIC_ARN:
            return HttpResponseBadRequest('Bad Topic')

    # Load the JSON POST Body
    if isinstance(request.body, str):
        # requests return str in python 2.7
        request_body = request.body
    else:
        # and return bytes in python 3.4
        request_body = request.body.decode()
    try:
        data = json.loads(request_body)
    except ValueError:
        logger.warning('Notification Not Valid JSON: {}'.format(request_body))
        return HttpResponseBadRequest('Not Valid JSON')
    logger.debug("subscription request(): data = %s" %
                 (json.dumps(data, sort_keys=True, indent=4, separators=(',', ': '))))

    # Ensure that the JSON we're provided contains all the keys we expect
    # Comparison code from http://stackoverflow.com/questions/1285911/
    if not set(VITAL_NOTIFICATION_FIELDS) <= set(data):
        logger.warning('Request Missing Necessary Keys')
        return HttpResponseBadRequest('Request Missing Necessary Keys')

    # Ensure that the type of notification is one we'll accept
    if not data['Type'] in ALLOWED_TYPES:
        logger.warning('Notification Type Not Known %s', data['Type'])
        return HttpResponseBadRequest('Unknown Notification Type')

    # Confirm that the signing certificate is hosted on a correct domain
    # AWS by default uses sns.{region}.amazonaws.com
    # On the off chance you need this to be a different domain, allow the
    # regex to be overridden in settings
    domain = urlparse(data['SigningCertURL']).netloc
    pattern = getattr(
        settings, 'FGTSCEVT_CERT_DOMAIN_REGEX', r"sns.[a-z0-9\-]+.amazonaws.com$"
    )
    logger.debug("subscription request(): domain = %s, pattern = %s" % (domain, pattern))
    if not re.search(pattern, domain):
        logger.warning(
            'Improper Certificate Location %s', data['SigningCertURL'])
        return HttpResponseBadRequest('Improper Certificate Location')

    # Verify that the notification is signed by Amazon
    if getattr(settings, 'FGTSCVT_VERIFY_CERTIFICATE', True) and not verify_notification(data):
        logger.warning('Verification Failure %s', )
        return HttpResponseBadRequest('Improper Signature')

    # Send a signal to say a valid notification has been received
    notification.send(sender='fortigate_autoscale', notification=data, request=request)

    # Handle subscription-based messages.
    if data['Type'] == 'SubscriptionConfirmation':
        # Allow the disabling of the auto-subscription feature
        if not getattr(settings, 'BOUNCY_AUTO_SUBSCRIBE', True):
            raise Http404
        return approve_subscription(data)
    elif data['Type'] == 'UnsubscribeConfirmation':
        # We won't handle unsubscribe requests here. Return a 200 status code
        # so Amazon won't redeliver the request. If you want to remove this
        # endpoint, remove it either via the API or the AWS Console
        logger.warning('UnsubscribeConfirmation Not Handled')
        return HttpResponse('UnsubscribeConfirmation Not Handled')

    try:
        message = json.loads(data['Message'])
    except ValueError:
        # This message is not JSON. But we need to return a 200 status code
        # so that Amazon doesn't attempt to deliver the message again
        logger.exception('Non-Valid JSON Message Received')
        return HttpResponse('Message is not valid JSON')

    logger.debug("subscription request(): message = %s, data = %s" % (message, data))
    return process_message(message, data)


def process_autoscale_group(asg_name):
    logger.info("process_autoscale_group(): asg = %s" % asg_name)
    table_found = False
    data = None
    g = AutoScaleGroup(data, asg_name)
    f = Fortigate(data, asg=g)
    try:
        t = g.db_client.describe_table(TableName=asg_name)
        if 'ResponseMetadata' in t:
            if t['ResponseMetadata']['HTTPStatusCode'] == STATUS_OK:
                table_found = True
    except g.db_client.exceptions.ResourceNotFoundException:
        logger.debug("process_autoscale_group_exception_1()")
        table_found = False
    if table_found is True:
        logger.info("process_autoscale_group(4): FOUND autoscale scale group table")
        mt = g.db_resource.Table(asg_name)
        try:
            a = mt.get_item(Key={"Type": TYPE_AUTOSCALE_GROUP, "TypeId": "0000"})
        except g.db_client.exceptions.ResourceNotFoundException:
            logger.exception("process_autoscale_group()")
            return
        if a is not None and 'Item' in a and 'MasterId' in a['Item']:
            instance_id = a['Item']['MasterId']
            g.remove_master(instance_id)
        if 'Item' in a and 'UpdateCountdown' in a['Item']:
            item = a['Item']
            if item['UpdateCountdown'] > 1:
                item['UpdateCountdown'] = item['UpdateCountdown'] - 1
                mt.put_item(Item=item)
            if item['UpdateCountdown'] == 1:
                logger.info("process_autoscale_group(7): UPDATING Autoscale Group Counts")
                counts_updated = False
                while counts_updated is False:
                    counts_updated = g.update_instance_counts()
                item['UpdateCountdown'] = 0
                mt.put_item(Item=item)
        logger.info("process_autoscale_group(5):")
        try:
            r = mt.query(KeyConditionExpression=Key('Type').eq(TYPE_ENI_ID))
        except Exception as ex:
            logger.exception('mt.query: ex = %s' % ex)
            raise Http404
        if r['Count'] > 0:
            for i in r['Items']:
                logger.info("process_autoscale_group(9): DELETE ENI")
                f.delete_second_interface(i)
        try:
            instances = mt.query(KeyConditionExpression=Key('Type').eq(TYPE_INSTANCE_ID))
        except Exception as ex:
            logger.exception('mt_query: ex = %s' % ex)
            return
        logger.info("process_autoscale_group(10): instances count = %s" % len(instances['Items']))
        if 'Items' in instances:
            if len(instances['Items']) > 0:
                for i in instances['Items']:
                    logger.info("process_autoscale_group(11): state = %s, countdown = %d" %
                                (i['State'], i['CountDown']))
                    if 'State' in i and (i['State'] == "LCH_LAUNCH" or i['State'] == "ADD_TO_AUTOSCALE_GROUP"):
                        if 'CountDown' in i and i['CountDown'] > 0:
                            value = i['CountDown']
                            value = value - 60
                            logger.info("process_autoscale_group(12): DECREMENT CountDown")
                            i['CountDown'] = value
                            mt.put_item(Item=i)
                        elif 'CountDown' in i and i['CountDown'] == 0:
                            e = mt.get_item(Key={"Type": TYPE_ENI_ID, "TypeId": i['SecondENIId']})
                            if 'Item' in e:
                                lch_name = e['Item']['LifecycleHookName']
                                lch_token = e['Item']['LifecycleToken']
                                action = 'CONTINUE'
                                time.sleep(random.randint(1, 5))
                                logger.info("process_autoscale_group(14): COMPLETE LCH lch_token = %s" % lch_token)
                                try:
                                    g.asg_client.complete_lifecycle_action(LifecycleHookName=lch_name,
                                                                           AutoScalingGroupName=g.name,
                                                                           LifecycleActionToken=lch_token,
                                                                           LifecycleActionResult=action)
                                except Exception as ex:
                                    logger.exception('process_autoscale_group EXCEPTION lch(): ex = %s' % ex)
                                    pass
                            logger.info("process_autoscale_group(15): Putting Instance In Service: i = %s" % i)
                            i['State'] = "InService"
                            mt.put_item(Item=i)
                        else:
                            pass
                    if 'State' in i and (i['State'] == "InService" or i['State'] == 'ADD_TO_AUTOSCALE_GROUP'):
                        instance_id = i['TypeId']
                        instance_not_found = False
                        logger.info("process_autoscale_group(20): status instance = %s" % instance_id)
                        r = None
                        try:
                            r = f.ec2_client.describe_instance_status(InstanceIds=[instance_id])
                            logger.info("process_autoscale_group(20a): Found InService Instance = %s" % instance_id)
                        except Exception as ex:
                            logger.info('process_autoscale_group EXCEPTION instance id(): ex = %s' % ex)
                            instance_not_found = True
                        if r is not None and 'InstanceStatuses' in r:
                            if len(r['InstanceStatuses']) > 0:
                                state = r['InstanceStatuses'][0]['InstanceState']['Name']
                                logger.info('process_autoscale_group(20c): state = %s' % state)
                                if state == 'terminated':
                                    instance_not_found = True
                                if state == 'running':
                                    instance_not_found = False
                            else:
                                instance_not_found = True
                        if instance_not_found is True:
                            if 'SecondENIId' in i:
                                eni = i['SecondENIId']
                                item = {"Type": TYPE_ENI_ID, "TypeId": eni,
                                        "AutoScaleGroupName": g.name,
                                        "LifecycleHookName": 'None', "LifecycleToken": 'None',
                                        "ENIId": eni}
                                mt.put_item(Item=item)
                            logger.info("process_autoscale_group(21): Removing From TableInService Instance = %s"
                                        % instance_id)
                            try:
                                mt.delete_item(Key={"Type": TYPE_INSTANCE_ID, "TypeId": instance_id})
                            except g.db_client.exceptions.ResourceNotFoundException:
                                logger.info('process_autoscale_group delete item(): Not Found id = %s' %
                                            instance_id)
    g.verify_byol_licenses()
    return

#
# If the autoscale group doesn't exist in AWS, delete the record in the master table and
# delete the autoscale group table in DynamoDB
#


def cleanup_database(master_table, asg_group):
    logger.info("cleanup_database(): %s" % asg_group)
    dbc = boto3.client('dynamodb')
    master_table.delete_item(Key={"Type": TYPE_AUTOSCALE_GROUP, "TypeId": asg_group})
    dbc.delete_table(TableName=asg_group)


#
# this function is only called via lambda due to a periodic cloudwatch cron
# see zappa_settings.json for configuration
#


@csrf_exempt
def start_scheduled(event, context):
    logger.info("start_scheduled(): =============== start start_scheduled 2.0 ============")
    extra = "fortinet_autoscale_"
    account = event['account']
    region = event['region']
    master_table_name = extra + region + "_" + account
    logger.debug("start_scheduled(): master_table_name = %s" % master_table_name)
    asg_client = boto3.client('autoscaling')
    dbc = boto3.client('dynamodb')
    dbr = boto3.resource('dynamodb')
    t = dbc.list_tables()
    logger.debug("start_scheduled4(): t = %s" % json.dumps(t, sort_keys=True, indent=4, separators=(',', ': ')))
    if 'TableNames' not in t:
        return
    if len(t['TableNames']) == 0:
        return
    table_found = False
    try:
        t = dbc.list_tables()
        if 'TableNames' in t:
            logger.info("Found table %s" % t['TableNames'])
            for i in range(len(t['TableNames'])):
                tn = t['TableNames'][i]
                if tn == master_table_name:
                    table_found = True
    except Exception as ex:
        logger.debug('list_tables(): ex = %s' % ex)
        table_found = False
    if table_found is False:
        logger.info("start_scheduled(): No Master Table Found")
        return
    try:
        t = dbc.describe_table(TableName=master_table_name)
        if 'TableStatus' in t['Table']:
            if t['Table']['TableStatus'] == 'ACTIVE':
                logger.debug("start_scheduled(): MASTER TABLE FOUND")
                table_found = True
    except Exception as ex:
        logger.exception('dbc.describe_table: ex = %s' % ex)
        table_found = False
    if table_found is True:
        mt = dbr.Table(master_table_name)
        try:
            r = mt.query(KeyConditionExpression=Key('Type').eq(TYPE_AUTOSCALE_GROUP))
        except dbc.exceptions.ResourceNotFoundException:
            logger.exception("start_scheduled_except_2()")
            re
        if 'Items' in r:
            logger.debug("found items in r:")
            if len(r['Items']) > 0:
                for asg in r['Items']:
                    logger.info("start_scheduled() FOUND autoscale group = %s" % asg['TypeId'])
                    group_name = asg['TypeId']
                    try:
                        r = asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[group_name])
                    except Exception as ex:
                        logger.exception("exeception start_scheduled() - describe_auto_scaling_groups(): ex = %s" % ex)
                        cleanup_database(mt, group_name)
                        return
                    if len(r['AutoScalingGroups']) == 0:
                        logger.info("start_scheduled6(): cleanup_autoscale_group_database = %s" % group_name)
                        cleanup_database(mt, group_name)
                        return
                    process_autoscale_group(asg['TypeId'])
    return

#
# This routine takes the place of start_scheduled() above, when running in django locally
#


@csrf_exempt
def start(event):
    # logger.info("start(): event = %s" % event)
    if event.method != 'POST':
        raise Http404
    data = None
    if isinstance(event.body, bytes):
        request_body = event.body.decode("utf-8")
        try:
            data = json.loads(request_body)
        except ValueError:
            logger.exception('start(): Notification Not Valid JSON: {}'.format(request_body))
            return HttpResponseBadRequest('Not Valid JSON')
    if isinstance(event.body, str):
        request_body = event.body
        try:
            data = json.loads(request_body)
        except ValueError:
            logger.exception('start(): Notification Not Valid JSON: {}'.format(request_body))
            return HttpResponseBadRequest('Not Valid JSON')
    logger.debug("start(): data = %s" % (json.dumps(data, sort_keys=True, indent=4, separators=(',', ': '))))
    extra = "fortinet_autoscale_"
    account = data['account']
    region = data['region']
    master_table_name = extra + region + "_" + account
    logger.debug("start_scheduled1(): master_table_name = %s" % master_table_name)
    dbc = boto3.client('dynamodb')
    logger.debug("start_scheduled2(): ")
    dbr = boto3.resource('dynamodb')
    logger.debug("start_scheduled3(): master_table_name = %s" % master_table_name)
    # t = dbc.list_tables(ExclusiveStartTableName=master_table_name, Limit=100)
    # logger.debug("start_scheduled4(): t = %s" % json.dumps(t, sort_keys=True, indent=4, separators=(',', ': ')))
    # if 'TableNames' not in t:
    #     return
    # if len(t['TableNames']) == 0:
    #     return
    logger.debug("start_scheduled5(): ")
    table_found = False
    try:
        t = dbc.describe_table(TableName=master_table_name)
        if 'TableStatus' in t['Table']:
            if t['Table']['TableStatus'] == 'ACTIVE':
                logger.debug("start_scheduled5a(): ")
                table_found = True
    except Exception as ex:
        logger.exception('dbc.describe_table: ex = %s' % ex)
        table_found = False
    logger.debug("start_scheduled6(): ")
    if table_found is True:
        logger.debug("start_scheduled7():")
        mt = dbr.Table(master_table_name)
        try:
            r = mt.query(KeyConditionExpression=Key('Type').eq(TYPE_AUTOSCALE_GROUP))
        except dbc.db_client.exceptions.ResourceNotFoundException:
            logger.exception("start_scheduled_except_2()")
            return
        if 'Items' in r:
            logger.debug("found items in r:")
            if len(r['Items']) > 0:
                for asg in r['Items']:
                    logger.debug("found autoscale group: master_table_name = %s" % asg['TypeId'])
                    process_autoscale_group(asg['TypeId'])
    return HttpResponse('0')


@csrf_exempt
def index(request):
    logger.debug("index(): request: %s", vars(request))
    return HttpResponse('0')


@csrf_exempt
def sns(request):
    logger.info("sns(): =============== start sns 2.0 ============")
    if request.method != 'POST':
        return HttpResponseBadRequest('Only POST Requests Accepted')
    body = request.body
    try:
        data = json.loads(body)
    except ValueError:
        logger.info('sns(): Notification Not Valid JSON: {}'.format(body))
        return HttpResponseBadRequest('Not Valid JSON')
    logger.info("sns(): request = %s" % (json.dumps(data, sort_keys=True, indent=4, separators=(',', ': '))))
    if 'Type' in data and data['Type'] != 'SubscriptionConfirmation':
        if 'Message' in data:
            try:
                msg = json.loads(data['Message'])
            except ValueError:
                logger.info('sns(): Notification Not Valid JSON: {}'.format(body))
                return HttpResponseBadRequest('Not Valid JSON')
            logger.info("sns(): message = %s" % (json.dumps(msg, sort_keys=True, indent=4, separators=(',', ': '))))
    if 'TopicArn' not in data:
        return HttpResponseBadRequest('Not Valid JSON')
    url = None
    if 'HTTP_HOST' in request.META:
        logger.info("sns(): http_host = %s" % request.META['HTTP_HOST'])
        host_url = request.META['HTTP_HOST']
        try:
            u, port = host_url.split(':')
        except ValueError:
            port = None
        #
        # Port 8000 is used by Django local server during debug
        #
        if port is not None and port == '8000':
            url = 'http://' + request.META['HTTP_HOST']
        else:
            url = 'https://' + request.META['HTTP_HOST'] + '/dev'
        logger.info("Callback url: %s" % url)
    #
    # Handle Subscription Request up front. The first Subscription request will trigger a DynamoDB table creation
    # and it will not be responded to. The second request will have an ACTIVE table and the subscription request
    # will be responded to and start the flow of Autoscale Messages.
    #
    if data['Type'] == 'SubscriptionConfirmation':
        master_table_found = False
        asg_table_found = False
        g = AutoScaleGroup(data)
        logger.debug('SubscriptionConfirmation 1(): g = %s' % g)
        master_table_name = "fortinet_autoscale_" + g.region + "_" + g.account
        i = 0
        try:
            t = g.db_client.list_tables()
            if 'TableNames' in t:
                logger.info("Found table %s" % t['TableNames'])
                for i in range(len(t['TableNames'])):
                    tn = t['TableNames'][i]
                    if tn == master_table_name:
                        master_table_found = True
                    if tn == g.name:
                        asg_table_found = True
        except Exception as ex:
            logger.debug('list_tables(): ex = %s' % ex)
            master_table_found = False
        if master_table_found is False:
            logger.info("Creating Master Table: %s" % master_table_name)
            try:
                g.db_client.create_table(AttributeDefinitions=attribute_definitions,
                                         TableName=master_table_name, KeySchema=schema,
                                         ProvisionedThroughput=provisioned_throughput)
            except Exception as ex:
                logger.exception('SubscriptionConfirmation master_table_create(): table_status = %s' % ex)
        if asg_table_found is False:
            logger.info("Creating Autoscale Group Table: %s" % g.name)
            try:
                g.db_client.create_table(AttributeDefinitions=attribute_definitions,
                                         TableName=g.name, KeySchema=schema,
                                         ProvisionedThroughput=provisioned_throughput)
            except Exception as ex:
                logger.exception('SubscriptionConfirmation master_table_create(): table_status = %s' % ex)
        if master_table_name is False or asg_table_found is False:
            response = HttpResponse("Creating Tables", status=100)
            return response
        try:
            r = g.db_client.describe_table(TableName=master_table_name)
        except Exception as ex:
            logger.exception('DB Client describe_table exception %s' % ex)
        if r is not None and 'ResponseMetaData':
            status_code = r['ResponseMetadata']['HTTPStatusCode']
            if status_code == STATUS_OK:
                if 'Table' in r and 'TableStatus' in r['Table']:
                    table_status = r['Table']['TableStatus']
                    if table_status != 'ACTIVE':
                        logger.info('SNS Retry Table Not Active: table_status = %s' % table_status)
                        response = HttpResponse("Creating Tables", status=100)
                        return response
        logger.info("Writing Master Table: auto scale group %s" % g.name)
        mt = g.db_resource.Table(master_table_name)
        asg = {"Type": TYPE_AUTOSCALE_GROUP, "TypeId": g.name, "UpdateCountdown": 3}
        master_table_written = False
        while master_table_written is False:
            try:
                mt.put_item(Item=asg)
                master_table_written = True
            except g.db_client.exceptions.ResourceNotFoundException:
                master_table_written = False
                time.sleep(5)
        #
        # End of master table
        #
        r = None
        table_status = 'NOTFOUND'
        try:
            r = g.db_client.describe_table(TableName=g.name)
        except Exception as ex:
            logger.exception('DB Client describe_table exception %s' % ex)
            table_status = 'NOTFOUND'

        if r is not None and 'Table' in r:
            table_status = r['Table']['TableStatus']
            logger.debug('SubscriptionConfirmation 2(): table_status = %s' % table_status)
        #
        # If NOTFOUND, fall through to write_to_db() and it will create the table
        #
        if table_status == 'NOTFOUND':
            pass
        #
        # If ACTIVE and we received a new Subscription Confirmation, delete everything in the table and start over
        #
        elif table_status == 'ACTIVE':
            table = g.db_resource.Table(g.name)
            response = table.scan()
            if 'Items' in response:
                for r in response['Items']:
                    table.delete_item(Key={"Type": r['Type'], "TypeId": r['TypeId']})
        #
        # If CREATING, this is the second Subscription Confirmation and AWS is still busy creating the table
        #   just ignore this request
        elif table_status == 'CREATING':
            return
        else:
            #
            # Unknown status. 404
            #
            raise Http404

        logger.info('SubscriptionConfirmation pre write_to_db()')
        g.write_to_db(data, url)

        logger.info('SubscriptionConfirmation post write_to_db(): g.status = %s' % g.status)
        if g.status == 'CREATING':
            return
        if g.asg is None:
            raise Http404

        if g.status == 'ACTIVE':
            logger.info('SubscriptionConfirmation respond_to_subscription request()')
            return respond_to_subscription_request(request)

    #
    # Handle the following NOTIFICATION TYPES: TEST, EC2_LCH_Launch, EC2_Launch, EC2_LCH_Terminate, EC2_Terminate
    #
    if 'Type' in data and data['Type'] == 'Notification':
        #
        # if this is a TEST_NOTIFICATION, just respond 200. Autoscale group is likely in te process of being created
        #
        logger.info("sns(notification 1))")
        g = AutoScaleGroup(data)
        logger.info("sns(notification 2): name = %s" % g.name)
        asg_name = g.name
        if 'Message' in data:
            logger.info("sns(notification 3)")
            try:
                msg = json.loads(data['Message'])
            except ValueError:
                logger.exception('sns(): Notification Not Valid JSON: {}'.format(data['Message']))
                return HttpResponseBadRequest('Not Valid JSON')
            if 'Event' in msg and msg['Event'] == 'autoscaling:TEST_NOTIFICATION':
                try:
                    t = g.db_client.describe_table(TableName=asg_name)
                    if 'ResponseMetadata' in t:
                        if t['ResponseMetadata']['HTTPStatusCode'] == STATUS_OK:
                            logger.info("sns(notification 4)")
                            table_found = True
                except g.db_client.exceptions.ResourceNotFoundException:
                    logger.info("process_autoscale_group_exception_1()")
                    table_found = False
                logger.info("sns(notification 5)")
                if table_found is True:
                    logger.info("sns(notification 6)")
                    logger.info("process_autoscale_group(4): FOUND autoscale scale group table")
                    mt = g.db_resource.Table(asg_name)
                    try:
                        a = mt.get_item(Key={"Type": TYPE_AUTOSCALE_GROUP, "TypeId": "0000"})
                    except g.db_client.exceptions.ResourceNotFoundException:
                        logger.exception("process_autoscale_group()")
                        return
                logger.info("sns(notification 7): a = %s" % a)
                if 'Item' in a and 'UpdateCountdown' in a['Item']:
                    logger.info("sns(notification 8)")
                    item = a['Item']
                    item['UpdateCountdown'] = 0
                    mt.put_item(Item=item)
                logger.info("sns(notification 11)")
                return HttpResponse(0)
            g = AutoScaleGroup(data)
            g.write_to_db(data, url)
            if g.asg is None:
                raise Http404
            rc = g.process_notification(data)
            if rc == STATUS_NOT_OK:
                response = HttpResponse("Instance Not Ready", status=100)
            else:
                response = HttpResponse(0)
            return response


@csrf_exempt
def callback(request):
    ip = None
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    if request.method != 'POST':
        raise Http404
    rpath = request.path
    callback_path = rpath.split('/')
    group = callback_path[len(callback_path) - 1]
    request_body = request.body
    if request_body is not None and request_body != '':
        i = json.loads(request_body)
        logger.info("callback(start): instance = %s, group = %s, ip = %s" % (i['instance'], group, ip))
    return HttpResponse(0)

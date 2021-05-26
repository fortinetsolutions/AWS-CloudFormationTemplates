import boto3
import json

from django.http import HttpResponseBadRequest, HttpResponse
import time
from .const import *
import base64
import re

from .fos_api import FortiOSAPI
from .Fortigate import Fortigate
from .RouteTable import RouteTable
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError


class AutoScaleGroup(object):
    def __init__(self, data, asg_name=None):
        if data is not None:
            if 'TopicArn' not in data:
                return
            if 'Type' not in data:
                return
        self.status = None
        self.asg = None
        self.asg_info = None
        self.table = None
        self.name = None
        self.route_tables = None
        self.instance_id_tables = None
        self.endpoint_url = None
        self.master_ip = None
        self.private_subnet_id = None
        self.cft_resource = boto3.resource('cloudformation')
        self.cft_client = boto3.client('cloudformation')
        self.db_resource = boto3.resource('dynamodb')
        self.db_client = boto3.client('dynamodb')
        self.asg_client = boto3.client('autoscaling')
        self.ec2_client = boto3.client('ec2')
        self.ec2_resource = boto3.resource('ec2')
        self.s3_client = boto3.client('s3')
        self.s3_resource = boto3.resource('s3')
        self.elbv2_client = boto3.client('elbv2')
        self.unused_licenses = []
        self.region = None
        self.account = None
        self.target_group = None
        self.cft_password = None
        self.SsmSecret = None
        if data is not None:
            p = data['TopicArn'].split(':')
            if len(p) != 6:
                self.name = None
            else:
                self.name = p[5]
                if self.name.endswith('-byol'):
                    self.table_name = self.name[:-5]
                if self.name.endswith('-paygo'):
                    self.table_name = self.name[:-6]
                self.account = p[4]
                self.region = p[3]
                self.update_asg_info()
                logger.debug('AutoScaleGroup init(a): table name = %s' % self.table_name)
        else:
            self.name = self.table_name = asg_name
            self.table = self.db_resource.Table(self.table_name)
            try:
                r = self.table.get_item(TableName=self.table_name, Key={"Type": TYPE_AUTOSCALE_GROUP, "TypeId": "0000"})
            except self.db_client.exceptions.ResourceNotFoundException:
                r = None
            if r is not None and 'ResponseMetadata' in r:
                status = r['ResponseMetadata']['HTTPStatusCode']
                if status == STATUS_OK:
                    if 'Item' in r:
                        self.asg = r['Item']
                        if 'EndPointUrl' in self.asg:
                            self.endpoint_url = self.asg['EndPointUrl']
        self.stack_name = self.get_tag('aws:cloudformation:stack-name')
        sport = self.get_tag('Fortigate-Admin-Sport')
        if sport is None:
            self.admin_sport = 443
        else:
            self.admin_sport = int(sport)
        self.api = FortiOSAPI(self.admin_sport)
        if self.stack_name is not None:
            c = self.cft_resource.Stack(self.stack_name)
            for v in c.parameters:
                key = v['ParameterKey']
                value = v['ParameterValue']
                if key == 'SsmSecureStringParamName':
                    self.SsmSecret = value
        if data is not None:
            if data['Type'] == 'Notification':
                self.table = self.db_resource.Table(self.table_name)
                try:
                    r = self.table.get_item(TableName=self.table_name,
                                            Key={"Type": TYPE_AUTOSCALE_GROUP, "TypeId": "0000"})
                except self.db_client.exceptions.ResourceNotFoundException:
                    r = None
                if r is not None and 'ResponseMetadata' in r:
                    status = r['ResponseMetadata']['HTTPStatusCode']
                    if status == STATUS_OK:
                        if 'Item' in r:
                            self.asg = r['Item']
                            if 'EndPointUrl' in self.asg:
                                self.endpoint_url = self.asg['EndPointUrl']
        if self.table is not None:
            t = self.table
            try:
                r = t.query(KeyConditionExpression=Key('Type').eq(TYPE_ROUTETABLE_ID))
            except self.db_client.exceptions.ResourceNotFoundException:
                return
            if 'Items' in r:
                if len(r['Items']) > 0:
                    self.route_tables = []
                for rt in r['Items']:
                    self.route_tables.append(rt)
            try:
                i = t.query(KeyConditionExpression=Key('Type').eq(TYPE_INSTANCE_ID))
            except self.db_client.exceptions.ResourceNotFoundException:
                return
            if 'Items' in i:
                if len(i['Items']) > 0:
                    self.instance_id_tables = []
                    for instance in i['Items']:
                        self.instance_id_tables.append(instance)
            if data is not None:
                if data['Type'] == 'SubscriptionConfirmation':
                    logger.debug('AutoscaleGroup Init Subscription Confirmation')
                    autoscale_group_wait_count = 5
                    while autoscale_group_wait_count > 0:
                        r = self.asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[self.name])
                        logger.debug('AutoscaleGroup Init Sub 1: group_wait_count = %d' % autoscale_group_wait_count)
                        if 'AutoScalingGroups' not in r:
                            logger.debug('AutoscaleGroup Init Subscription Confirmation 2')
                            time.sleep(3)
                            autoscale_group_wait_count = autoscale_group_wait_count - 1
                            continue
                        if len(r['AutoScalingGroups']) == 0:
                            logger.debug('AutoscaleGroup Init Subscription Confirmation 3')
                            time.sleep(3)
                            autoscale_group_wait_count = autoscale_group_wait_count - 1
                            continue
                        autoscale_group_wait_count = 0
        return

    def __repr__(self):
        return ' () ' % ()

    def check_group_table(self, table):
        reset_table = False
        try:
            a = table.get_item(Key={"Type": TYPE_AUTOSCALE_GROUP, "TypeId": "0000"})
        except self.db_client.exceptions.ResourceNotFoundException:
            logger.exception("check_group_table(1)")
            return False
        if a is not None and 'Items' in a:
            asg = a['Item']
            if self.name.endswith('-byol'):
                if 'AutoScaleGroupName_BYOL' in asg:
                    if asg['AutoScaleGroupName_BYOL'] == 'undefined':
                        asg['AutoScaleGroup_BYOL'] = self.name
                        reset_table = False
                        table.put_item(Item=asg)
                    else:
                        reset_table = True
            elif self.name.endswith('-paygo'):
                if 'AutoScaleGroupName_PAYGO' in asg:
                    if asg['AutoScaleGroupName_PAYGO'] == 'undefined':
                        asg['AutoScaleGroup_PAYGO'] = self.name
                        reset_table = False
                        table.put_item(Item=asg)
                    else:
                        reset_table = True
            else:
                reset_table = True
        else:
            reset_table = False
        return reset_table

    # Use this code snippet in your app.
    # If you need more information about configurations or implementing the sample code, visit the AWS docs:
    # https://aws.amazon.com/developers/getting-started/python/

    def get_secret(self, secret_name):

        client = boto3.client('ssm')

        try:
            r = client.get_parameter(Name=secret_name, WithDecryption=True)
        except Exception as error:
            logger.error('<--!! Exception: {}'.format(error))
            return None
        if 'ResponseMetadata' not in r:
            return None
        if 'HTTPStatusCode' not in r['ResponseMetadata']:
            return None
        if r['ResponseMetadata']['HTTPStatusCode'] != STATUS_OK:
            return None
        if 'Parameter' in r and 'Name' in r['Parameter'] and 'Value' in r['Parameter']:
            if r['Parameter']['Name'] == secret_name:
                return r['Parameter']['Value']

    def update_asg_info(self):
        if self.name is not None:
            try:
                r = self.asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[self.name])
            except Exception as ex:
                logger.exception("exeception - describe_auto_scaling_groups(): ex = %s" % ex)
                return
            if len(r['AutoScalingGroups']) == 1:
                self.asg_info = r['AutoScalingGroups'][0]
                return

    #
    # Find a tag that matches key on this Fortigate
    #
    def get_tag(self, key):
        if self.asg_info is None:
            self.update_asg_info()
        if self.asg_info is None:
            return None
        if 'Tags' not in self.asg_info:
            return None
        tags = self.asg_info['Tags']
        for t in tags:
            if t['Key'] == key:
                return t['Value']
        return None

    def update_asg_counts(self, name):
        try:
            r = self.asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[name])
        except Exception as ex:
            logger.exception("exeception - describe_auto_scaling_groups(): ex = %s" % ex)
            return
        if len(r['AutoScalingGroups']) == 1:
            tags = r['AutoScalingGroups'][0]['Tags']
            min_size = None
            for t in tags:
                if t['Key'] == 'Fortigate-AutoScale-Group-MinSize':
                    min_size = t['Value']
            if min_size is None:
                return
            size = int(min_size)
            logger.info('update_asg_count: name = %s, size = %d' % (name, size))
            if size == 0:
                return
            try:
                self.asg_client.update_auto_scaling_group(AutoScalingGroupName=name,
                                                          MinSize=size, DesiredCapacity=size)
            except Exception as ex:
                logger.exception("exeception - update_auto_scaling_group(): ex = %s" % ex)
            return

    #
    # This is used to delay the creation of instances until the TEST_NOTIFICATION is sent. TEST_NOTIFICATION
    # indicates that the SNS Subscription is valid and SNS Notifications will not be lost and cause
    # initial instances to get stuck in Pending::WAIT state.
    #
    def update_instance_counts(self, asg_name):
        if asg_name is not None:
            name = asg_name + '-byol'
            self.update_asg_counts(name)
            name = asg_name + '-paygo'
            self.update_asg_counts(name)
        return True

    def delete_table(self):
        table_found = True
        t = None
        try:
            t = self.db_client.describe_table(TableName=self.table_name)
            if 'ResponseMetadata' in t:
                if t['ResponseMetadata']['HTTPStatusCode'] == STATUS_OK:
                    table_found = True
        except self.db_client.exceptions.ResourceNotFoundException:
            table_found = False
        if table_found is True:
            if 'Table' in t and t['Table']['TableStatus'] == 'ACTIVE':
                logger.debug('delete_table(): Table Found for SubscriptionRequest - table = %s' % self.name)
                self.db_client.delete_table(TableName=self.table_name)
                self.status = 'DELETING'
                while self.status == 'DELETING':
                    time.sleep(3)
                    try:
                        t = self.db_client.describe_table(TableName=self.table_name)
                    except self.db_client.exceptions.ResourceNotFoundException:
                        return
                    if 'Table' in t and 'TableStatus' in t['Table']:
                        self.status = t['Table']['TableStatus']

    def find_s3_cert_file(self, bucket):
        logger.info("find_s3_cert_file(1): bucket = %s" % bucket)
        if bucket is None:
            return None
        s3c = self.s3_client
        if s3c is None:
            return None
        s3buckets = s3c.list_buckets()
        s3lbucket_exists = False
        if 'Buckets' in s3buckets:
            for b in s3buckets['Buckets']:
                if 'Name' in b:
                    if b['Name'] == bucket:
                        s3lbucket_exists = True
                        break
        if s3lbucket_exists is False:
            return None
        objects = s3c.list_objects(Bucket=bucket)
        if 'Contents' not in objects:
            return None
        for o in objects['Contents']:
            logger.info("find_s3_cert_file(6): object = %s" % o['Key'])
            suffix = o['Key'].split('.')
            if len(suffix) == 2 and suffix[1] == 'cert':
                self.write_license_to_db(bucket, o['Key'])

    def find_s3_license_file(self, bucket):
        logger.info("find_s3_license_file(1): bucket = %s" % bucket)
        if bucket is None:
            return None
        s3c = self.s3_client
        if s3c is None:
            return None
        s3buckets = s3c.list_buckets()
        s3lbucket_exists = False
        if 'Buckets' in s3buckets:
            for b in s3buckets['Buckets']:
                if 'Name' in b:
                    if b['Name'] == bucket:
                        s3lbucket_exists = True
                        break
        if s3lbucket_exists is False:
            return None
        objects = s3c.list_objects(Bucket=bucket)
        if 'Contents' not in objects:
            return None
        for o in objects['Contents']:
            logger.info("find_s3_license_file(6): object = %s" % o['Key'])
            suffix = o['Key'].split('.')
            if len(suffix) == 2 and suffix[1] == 'lic':
                self.write_license_to_db(bucket, o['Key'])
        logger.info("find_s3_license_file(exit): bucket = %s" % bucket)

    def assign_license_to_instance(self, fortigate):
        logger.info("assign_license_to_instance()")
        if fortigate.ec2 is None:
            return
        t = self.db_resource.Table(self.name)
        try:
            results = t.query(TableName=self.table_name, KeyConditionExpression=Key('Type').eq(TYPE_BYOL_LICENSE))
        except Exception as e:
            logger.exception('no licenses found(): autoscale scale group = %s' % e)
            return None
        #
        # Check to see if this instance id already has a license.
        #
        l = None
        for l in results['Items']:
            if l['InstanceOwner'] == fortigate.instance_id:
                return -2
        for l in results['Items']:
            if l['InstanceOwner'] == 'unused':
                break
        if l is None or 'Bucket' not in l:
            return None
        bucket = l['Bucket']
        object_key = l['TypeId']
        s3c = self.s3_client
        f = object_key.split('/')
        fp = None
        for file_path in f:
            if file_path.endswith('.lic'):
                fp = file_path
                break
        if fp is None:
            return None
        file = '/tmp/' + fp
        with open(file, 'wb') as content:
            try:
                status = s3c.download_fileobj(bucket, object_key, content)
            except Exception as ex:
                logger.exception("caught: %s with download_fileobj():" % ex.message)
        ip = None
        if 'PublicIpAddress' in fortigate.ec2:
            ip = fortigate.ec2['PublicIpAddress']
        elif 'PrivateIpAddress' in self.ec2:
            ip = fortigate.ec2['PrivateIpAddress']
        logger.info("PutLicense found a key = %s" % object_key)
        instance_id = fortigate.instance_id
        status = fortigate.api.login(ip, 'admin', self.cft_password)
        if status == -1:
            logger.info("PutLicense after api.login: status = %d" % status)
            return status
        r = fortigate.api.get(api='monitor', path='license', name='status')
        try:
            data = json.loads(r)
        except json.decoder.JSONDecodeError:
            logger.exception("login.exception(api.get)")
            return -1
        if 'results' not in data or 'vm' not in data['results'] or 'valid' not in data['results']['vm']:
            return -1
        license_valid = data['results']['vm']['valid']
        if license_valid is True:
            logger.info("PutLicense - this instance has a license")
        if license_valid is False:
            logger.info("PutLicense - this instance needs a license")
            b64lic = base64.b64encode(open(file).read().encode()).decode()
            logger.info("PutLicense before api.post.")
            status = fortigate.api.post(api='monitor', path='system', name='vmlicense',
                                        action='upload', data={"file_content": b64lic})
            status_type = type(status)
            if not isinstance(status, bytes):
                return -1
            try:
                msg = json.loads(status)
            except json.decoder.JSONDecodeError:
                logger.exception("login.exception(2): status = %s" % status)
                return -1
            if 'status' not in msg:
                logger.info("PutLicense api.put bad message status")
                return -1
            if msg['status'] != 'success':
                logger.info("PutLicense failed: %s status = %s" % (fortigate.instance_id, msg['status']))
                return -1
        logger.info("PutLicense - instance now has a license: %s status = %s, file = %s" % (fortigate.instance_id, status, file))
        self.write_license_to_db(bucket=bucket, key=l['TypeId'], instance_id=instance_id)
        return status

    def write_license_to_db(self, bucket, key, instance_id=None):
        table_found = True
        try:
            t = self.db_client.describe_table(TableName=self.table_name)
            if 'ResponseMetadata' in t:
                if t['ResponseMetadata']['HTTPStatusCode'] == STATUS_OK:
                    table_found = True
        except self.db_client.exceptions.ResourceNotFoundException:
            table_found = False
        if table_found is False:
            return None
        if self.table is None:
            self.table = self.db_resource.Table(self.name)
        try:
            r = self.table.get_item(TableName=self.table_name, Key={"Type": TYPE_BYOL_LICENSE, "TypeId": key})
        except self.db_client.exceptions.ResourceNotFoundException:
            r = None
        if r is not None and 'Item' in r:
            size = r['Item']['Size']
            lf = r['Item']
        else:
            size = 0
            lf = None
        if instance_id is None and lf is not None:
            return STATUS_OK
        if instance_id is None:
            owner = "unused"
            ldb = {"Type": TYPE_BYOL_LICENSE, "TypeId": key, "Bucket": bucket,
                   "Size": size, "InstanceOwner": owner}
            try:
                self.table.put_item(Item=ldb)
            except Exception as e:
                logger.exception('exception write_license_to_db():  e = %s' % e)
                return None
        else:
            owner = r['Item']['InstanceOwner']
            if owner == 'unused':
                owner = instance_id
                ldb = {"Type": TYPE_BYOL_LICENSE, "TypeId": key, "Bucket": bucket,
                     "Size": size, "InstanceOwner": owner}
                try:
                    self.table.put_item(Item=ldb)
                except Exception as e:
                    logger.exception('exception write_license_to_db():  e = %s' % e)
                    return None
        return STATUS_OK

    def write_to_db(self, data, url=None):
        if self.name is None:
            return
        if 'Type' not in data:
            return
        if 'Token' not in data:
            return
        notification_type = data['Type']
        subscribe_url = data['SubscribeURL']
        table_found = True
        t = None
        try:
            t = self.db_client.describe_table(TableName=self.table_name)
            if 'ResponseMetadata' in t:
                if t['ResponseMetadata']['HTTPStatusCode'] == STATUS_OK:
                    table_found = True
        except self.db_client.exceptions.ResourceNotFoundException:
            table_found = False
        if table_found is False:
            self.db_client.create_table(AttributeDefinitions=attribute_definitions,
                                        TableName=self.table_name, KeySchema=schema,
                                        ProvisionedThroughput=provisioned_throughput)
            self.status = 'CREATING'
            while self.status == 'CREATING':
                time.sleep(3)
                t = self.db_client.describe_table(TableName=self.table_name)
                if 'Table' in t and 'TableStatus' in t['Table']:
                    self.status = t['Table']['TableStatus']
        if 'Table' in t and 'TableStatus' in t['Table']:
            self.status = t['Table']['TableStatus']
        if self.table is None:
            self.table = self.db_resource.Table(self.table_name)
        try:
            r = self.table.get_item(TableName=self.table_name, Key={"Type": TYPE_AUTOSCALE_GROUP, "TypeId": "0000"})
        except self.db_client.exceptions.ResourceNotFoundException:
            r = None
        if r is not None and 'ResponseMetadata' in r:
            status = r['ResponseMetadata']['HTTPStatusCode']
            if status == STATUS_OK:
                if 'Item' in r:
                    if notification_type == 'SubscriptionConfirmation':
                        byol_name = ""
                        paygo_name = ""
                        if 'Item' in r:
                            byol_name = r['Item']['AutoScaleGroupName_BYOL']
                            paygo_name = r['Item']['AutoScaleGroupName_PAYGO']
                        if self.name.endswith('-byol'):
                            byol_name = self.name
                        if self.name.endswith('-paygo'):
                            paygo_name = self.name
                        self.asg = {"Type": TYPE_AUTOSCALE_GROUP, "TypeId": "0000",
                                    "AutoScaleGroupName_BYOL": byol_name, "AutoScaleGroupName_PAYGO": paygo_name,
                                    "SubscribeURL": subscribe_url,
                                    "TimeStamp": data['Timestamp'], "UpdateCountdown": 3}
                        if url is not None:
                            self.asg.update({"EndPointUrl": url})
                        try:
                            r = self.table.put_item(Item=self.asg)
                        except self.db_client.exceptions.ResourceNotFoundException:
                            return
                        if r is not None and 'ResponseMetadata' in r:
                            if 'HTTPStatusCode' in r['ResponseMetadata']:
                                status = r['ResponseMetadata']['HTTPStatusCode']
                                if status != STATUS_OK:
                                    self.asg = None
                                self.status = 'ACTIVE'
                        return
                    elif notification_type == 'Notification':
                        self.asg = r['Item']
                        return
                    else:
                        #
                        # not SUBSCRIBE or NOTIFY
                        #
                        self.asg = None
                else:
                    if notification_type == 'NOTIFY':
                        self.asg = None
                        return
        #
        # Type is SUBSCRIBE and the Subscribe Entry is not in the DB
        #
        if self.asg is None:
            byol_name = "unsubscribed"
            paygo_name = "unsubscribed"
            if self.name.endswith('-byol'):
                byol_name = self.name
            if self.name.endswith('-paygo'):
                paygo_name = self.name
            self.asg = {"Type": TYPE_AUTOSCALE_GROUP, "TypeId": "0000",
                        "AutoScaleGroupName_BYOL": byol_name, "AutoScaleGroupName_PAYGO": paygo_name,
                        "SubscribeURL": subscribe_url,
                        "TimeStamp": data['Timestamp'], "UpdateCountdown": 3}
            if url is not None:
                self.asg.update({"EndPointUrl": url})
            try:
                r = self.table.put_item(Item=self.asg)
            except self.db_client.exceptions.ResourceNotFoundException:
                return
            if r is not None and 'ResponseMetadata' in r:
                if 'HTTPStatusCode' in r['ResponseMetadata']:
                    status = r['ResponseMetadata']['HTTPStatusCode']
                    if status != STATUS_OK:
                        self.asg = None
                    self.status = 'ACTIVE'

        return

    #
    # Lifecycle Hook Launch message: create second nic, attach to private subnet,
    #   put instance_id in DB, return OK to respond to lifecycle hook
    #
    # If this is the first LifeCycleHook call, use the metadata (list of subnets)
    # passed in by CFT or Terraform to find all the route tables used by this VPC.
    #
    def lch_launch(self, data):
        if 'Message' not in data:
            return STATUS_OK
        try:
            msg = json.loads(data['Message'])
        except ValueError:
            logger.warning('sns(): Notification Not Valid JSON: {}'.format(data['Message']))
            return STATUS_OK
        if 'NotificationMetadata' not in msg:
            logger.warning('lch_launch(): no metadata in lch launch notification')
            return STATUS_OK
        f = Fortigate(data, self)
        logger.info('lch_launch(): Fortigate = %s, lch_token = %s' % (f, f.lch_token))
        metadata = msg['NotificationMetadata']
        subnets = metadata.split(":")
        if self.route_tables is None:
            i = 0
            self.route_tables = []
            #
            # Only lookup route table for 1 indexed subnets (Private Subnets)
            #
            while i < len(subnets):
                odd = i % 2
                if odd:
                    r = RouteTable(self, subnets[i])
                    if r.route_table_id is not None:
                        r.write_to_db()
                        rt = {"Subnet": r.subnet_id, "TypeId": r.route_table_id, "NetworkInterfaceId": r.eni}
                        self.route_tables.append(rt)
                i = i + 1
        logger.info('lch_launch(): subnets = %s' % subnets)
        rc = f.attach_second_interface(subnets)
        if rc == STATUS_OK:
            instance = {"Type": TYPE_INSTANCE_ID, "TypeId": f.instance_id,
                        "AutoScaleGroupName": self.name, "State": "LCH_LAUNCH",
                        "PrivateSubnetId": f.private_subnet_id, "CountDown": 60,
                        "SecondENIId": f.second_nic_id, "TimeStamp": f.timestamp}
            self.table.put_item(Item=instance)
            f.lch_action('CONTINUE')
        return STATUS_OK

    def lch_terminate(self, data):
        f = Fortigate(data, self)
        logger.info('lch_terminate(): instance = %s, second_eni = %s' % (f.instance_id, f.second_nic_id))
        if f.auto_scale_group is None:
            return
        f.detach_second_interface()
        if f.lch_token is not None:
            f.lch_action('CONTINUE')
        return STATUS_OK

    def remove_master(self, instance_id):
        logger.debug('remove_master(1): instance = %s' % instance_id)
        try:
            r = self.ec2_client.describe_instances(InstanceIds=[instance_id])
        except Exception as ex:
            logger.exception("remove_master() Error describing instance: %s, ex = %s" % (r, ex))
        if r is not None and 'Reservations' in r:
            if len(r['Reservations']) > 0:
                id = r['Reservations'][0]['Instances'][0]['InstanceId']
                state = r['Reservations'][0]['Instances'][0]['State']['Name']
                if state != 'terminated':
                    logger.debug('Master is healthy. Not removing: id = %s, state = %s' % (id, state))
                    return
                else:
                    logger.info('remove_master: id = %s, state = %s' % (id, state))
        try:
            r = self.table.get_item(TableName=self.table_name, Key={"Type": TYPE_AUTOSCALE_GROUP, "TypeId": "0000"})
        except self.db_client.exceptions.ResourceNotFoundException:
            r = None
        if 'Item' in r and 'MasterId' in r['Item'] and r['Item']['MasterId'] == instance_id:
            self.table.update_item(Key={"Type": TYPE_AUTOSCALE_GROUP, "TypeId": "0000"},
                                   UpdateExpression="remove MasterIp, MasterId")
        return

    def launch_instance(self, data):
        f = Fortigate(data, self)
        if f.ec2 is None:
            return
        num_enis = len(f.ec2['NetworkInterfaces'])
        logger.info('lch_launch_instance(): Fortigate = %s, lch_token = %s, enis = %d, group = %s' %
                    (f, f.lch_token, num_enis, f.auto_scale_group))
        if len(f.ec2['NetworkInterfaces']) < 2:
            self.ec2_client.terminate_instances(InstanceIds=[f.instance_id])
            try:
                self.table.delete_item(Key={"Type": TYPE_INSTANCE_ID, "TypeId": f.instance_id})
            except self.db_client.exceptions.ResourceNotFoundException:
                pass
            return STATUS_OK
        if f.auto_scale_group is None:
            return STATUS_OK
        try:
            i = self.table.get_item(TableName=self.table_name, Key={"Type": TYPE_INSTANCE_ID, "TypeId": f.instance_id})
        except self.db_client.exceptions.ResourceNotFoundException:
            i = None
        if i is None or 'Item' not in i:
            logger.info('lch_launch_instance(1a):')
            return STATUS_OK
        instance = i['Item']
        if instance['State'] == 'LCH_LAUNCH':
            logger.info('lch_launch_instance(1b): Instance Not ready to go InService. i = %s ' % f.instance_id)
            return STATUS_NOT_OK

        if self.cft_password == '' or self.cft_password is None:
            self.cft_password = self.get_secret(self.SsmSecret)
        key = 'Fortigate-License'
        license_type = f.get_tag(key)
        instance = i['Item']
        license_applied = False
        if instance['State'] == 'ADD_TO_AUTOSCALE_GROUP' or instance['State'] == 'InService':
            license_applied = True
        if instance['State'] == 'Waiting_For_License' and license_type == 'paygo':
            instance['State'] = 'ADD_TO_AUTOSCALE_GROUP'
            self.table.put_item(Item=instance)
            license_applied = True
        logger.info('lch_launch_instance(1c): state = %s, license_applied %s, license_type = %s' %
                    (instance['State'], license_applied, license_type))
        if license_applied is False and license_type == 'byol':
            key = 'Fortigate-S3-License-Bucket'
            license_bucket = f.get_tag(key)
            logger.info('lch_launch_instance(1d): type = %s, bucket = %s' % (license_type, license_bucket))
            self.find_s3_license_file(license_bucket)
            rc = self.assign_license_to_instance(f)
            if rc == -1:
                return STATUS_NOT_OK
            #
            # if rc is -2, the instance already has a license and the message is a duplicate.
            # Just return STATUS_OK and ignore it.
            #
            if rc == -2:
                logger.info('lch_launch_instance(1e): received duplicate EC2_LAUNCH')
                return STATUS_OK
            instance['State'] = 'ADD_TO_AUTOSCALE_GROUP'
            instance['CountDown'] = 120
            self.table.put_item(Item=instance)
            return STATUS_NOT_OK

        try:
            asg = self.table.get_item(TableName=self.table_name, Key={"Type": TYPE_AUTOSCALE_GROUP, "TypeId": "0000"})
        except self.db_client.exceptions.ResourceNotFoundException:
            asg = None
        if instance['State'] == 'ADD_TO_AUTOSCALE_GROUP' and instance['CountDown'] > 0:
            logger.info('lch_launch_instance2(): waiting for license reboot countdown = %d' % instance['CountDown'])
            return STATUS_NOT_OK
        self.remove_master(f.instance_id)
        if (asg is not None) and ('Item' in asg) and ('MasterIp' in asg['Item']):
            #
            # This is a slave
            #
            self.master_ip = asg['Item']['MasterIp']
            logger.info('lch_launch_instance4(): slave info master_ip = %s' % self.master_ip)
        else:
            #
            # This is the master
            #
            self.master_ip = f.ec2['PrivateIpAddress']
            self.table.update_item(Key={"Type": TYPE_AUTOSCALE_GROUP, "TypeId": "0000"},
                                   UpdateExpression="set MasterIp = :m, MasterId = :i, OrigMasterId = :p",
                                   ExpressionAttributeValues={':m': self.master_ip, ':i': f.ec2['InstanceId'],
                                                              ':p': f.ec2['InstanceId']})
            self.asg.update([('MasterId', f.ec2['InstanceId'])])
        if 'PrivateSubnetId' in instance:
            self.private_subnet_id = instance['PrivateSubnetId']
        rc = f.add_member_to_autoscale_group(self.master_ip, self.cft_password)
        if rc == -1:
            logger.info('lch_launch_instance5a(): DB instance = %s failed to add to autoscale group' % instance)
            return STATUS_NOT_OK
        instance['State'] = 'InService'
        self.table.put_item(Item=instance)
        if 'MasterId' in self.asg and f.ec2['InstanceId'] == self.asg['MasterId']:
            key = 'Fortigate-S3-License-Bucket'
            license_bucket = f.get_tag(key)
            f.write_certificate_to_master(license_bucket, key)
            logger.info('lch_launch_instance7(): ADDING MASTER')
        else:
            logger.info('lch_launch_instance7(): ADDING SLAVE')
        return STATUS_OK

    def terminate_instance(self, data):
        f = Fortigate(data, self)
        try:
            r = self.table.get_item(TableName=self.table_name, Key={"Type": TYPE_INSTANCE_ID, "TypeId": f.instance_id})
        except self.db_client.exceptions.ResourceNotFoundException:
            r = None
        if r is None or 'Item' not in r:
            logger.info('lch_launch_instance(1a): lch_token = %s' % f.lch_token)
            if f.lch_token is not None:
                f.lch_action('CONTINUE')
            return STATUS_OK
        instance = r['Item']
        if 'SecondENIId' in instance:
            eni = instance['SecondENIId']
            t = self.table
            item = {"Type": TYPE_ENI_ID, "TypeId": eni,
                    "AutoScaleGroupName": self.name,
                                         "LifecycleHookName": f.lch_name, "LifecycleToken": f.lch_token,
                                         "ENIId": eni}
            t.put_item(Item=item)
        new_master_pip = None
        self.table.delete_item(Key={"Type": TYPE_INSTANCE_ID, "TypeId": f.instance_id})
        if self.table is not None:
            v = f.get_tag('Fortigate-License')
            if v == 'byol':
                try:
                    results = self.table.query(TableName=self.table_name, KeyConditionExpression=Key('Type').eq(TYPE_BYOL_LICENSE))
                except Exception as e:
                    results = None
                    logger.exception('no licenses found(): autoscale scale group = %s' % e)
                if results is not None:
                    for lf in results['Items']:
                        if lf['InstanceOwner'] == f.instance_id:
                            lf['InstanceOwner'] = 'unused'
                            self.table.put_item(Item=lf)
            if 'MasterId' in self.asg and f.instance_id == self.asg['MasterId']:
                logger.info("Lost auto-scale Master instance: %s" % f.instance_id)
                try:
                    i = self.table.query(KeyConditionExpression=Key('Type').eq('0010'),
                                         ProjectionExpression="#t, #i",
                                         ExpressionAttributeNames={'#t': 'TypeId', '#i': 'TimeStamp'})
                except self.db_client.exceptions.ResourceNotFoundException:
                    return STATUS_OK
                db_dict = {}
                if i is not None and 'Items' in i:
                    for item in i['Items']:
                        db_dict.update({item['TimeStamp']: item['TypeId']})
                    for entry in sorted(db_dict.keys()):
                        if entry in sorted(db_dict.keys())[0]:
                            logger.debug("New Master %s with oldest timestamp: %s" % (db_dict[entry], entry))
                            # get instance primary private and public ip
                            try:
                                instance = self.ec2_client.describe_instances(InstanceIds=[db_dict[entry]])
                            except Exception as ex:
                                logger.exception("Error describing instance: %s, ex = %s" % (db_dict[entry], ex))
                                return STATUS_OK
                            new_master_pip = instance['Reservations'][0]['Instances'][0]['PrivateIpAddress']
                            new_master_eip = instance['Reservations'][0]['Instances'][0]['PublicIpAddress']
                            # update db: type 0000 with new IP and ID
                            self.table.update_item(Key={"Type": TYPE_AUTOSCALE_GROUP, "TypeId": "0000"},
                                                   UpdateExpression="set MasterIp = :m, MasterId = :i",
                                                   ExpressionAttributeValues={':m': new_master_pip,
                                                                              ':i': db_dict[entry]})
                            # update fortios: set config sys auto-scale as master
                            callback_url = self.asg['EndPointUrl'] + "/callback/" + self.asg['AutoScaleGroupName']
                            data = {
                                  "status": "enable",
                                  "role": "master",
                                  "sync-interface": "port1",
                                  "psksecret": self.asg['AutoScaleGroupName'],
                                  "callback-url": callback_url
                            }
                            logger.info('posting auto-scale config: {}' .format(data))
                            self.api.login(new_master_eip, 'admin', self.cft_password)
                            content = self.api.put(api='cmdb', path='system', name='auto-scale', data=data)
                            self.api.logout()
                            logger.info('restapi response: {}' .format(content))
                            # update instance tag: set 'Fortinet-Autoscale' to 'Master'
                            self.ec2_client.create_tags(Resources=[db_dict[entry]],
                                                        Tags=[{'Key': 'Fortinet-Autoscale', 'Value': 'Master'}])
                        else:
                            logger.debug("Existing Slave %s with timestamp: %s" % (db_dict[entry], entry))
                            # get instance primary public ip
                            try:
                                instance = self.ec2_client.describe_instances(InstanceIds=[db_dict[entry]])
                            except Exception as ex:
                                logger.debug("Error describing instance: %s, ex = %s" % (db_dict[entry], ex))
                                return STATUS_OK
                            existing_slave_eip = instance['Reservations'][0]['Instances'][0]['PublicIpAddress']
                            # update fortios: set config sys auto-scale to point to new master
                            try:
                                r2 = self.table.get_item(TableName=self.table_name, Key={"Type": TYPE_AUTOSCALE_GROUP,
                                                                                   "TypeId": "0000"},
                                                         ProjectionExpression="MasterIp")
                            except self.db_client.exceptions.ResourceNotFoundException:
                                r2 = None
                                return STATUS_OK
                            master_ip = r2['Item']['MasterIp']
                            callback_url = self.asg['EndPointUrl'] + "/callback/" + self.asg['AutoScaleGroupName']
                            data = {
                                  "status": "enable",
                                  "role": "slave",
                                  "master-ip": new_master_pip,
                                  "sync-interface": "port1",
                                  "psksecret": self.asg['AutoScaleGroupName'],
                                  "callback-url": callback_url
                            }
                            logger.info('posting auto-scale config: {}' .format(data))
                            self.api.login(existing_slave_eip, 'admin', self.cft_password)
                            content = self.api.put(api='cmdb', path='system', name='auto-scale', data=data)
                            self.api.logout()
                            logger.info('restapi response: {}' .format(content))
        return STATUS_OK

    @staticmethod
    def get_aws_route_info(rtid, routes):
        subnet_id = None
        nic_id = None
        state = None
        cidr_block = None
        if 'RouteTables' in routes:
            for route in routes['RouteTables']:
                if 'RouteTableId' in route:
                    if route['RouteTableId'] != rtid:
                        continue
                if 'SubnetId' not in route['Associations'][0]:
                    continue
                subnet_id = route['Associations'][0]['SubnetId']
                if 'Routes' in route:
                    for r in route['Routes']:
                        if 'DestinationCidrBlock' in r and r['DestinationCidrBlock'] == '0.0.0.0/0':
                            cidr_block = r['DestinationCidrBlock']
                            if 'NetworkInterfaceId' in r:
                                nic_id = r['NetworkInterfaceId']
                                state = r['State']
        return {"RouteTableId": rtid, "SubnetId": subnet_id, "NetworkInterfaceId": nic_id,
                "DestinationCidrBlock": cidr_block, "State": state}

    def get_nic_status(self, nic):
        try:
            r = self.ec2_client.describe_network_interfaces(NetworkInterfaceIds=[nic])
        except ClientError as e:
            logger.exception('exception describe_network_interface():  %s' % e.Response)
            return False
        if 'NetworkInterfaces' in r and len(r['NetworkInterfaces']) > 0:
            if r['NetworkInterfaces'][0]['Status'] != 'in-use':
                return False
        return True

    def find_best_eni(self, subnet_id):
        nic = None
        if self.instance_id_tables is None:
            return None
        if len(self.instance_id_tables) > 0:
            for i in self.instance_id_tables:
                if i['PrivateSubnetId'] == subnet_id:
                    rc = self.get_nic_status(i['SecondENIId'])
                    if rc is True:
                        nic = i['SecondENIId']
                        break
                if nic is None:
                    rc = self.get_nic_status(i['SecondENIId'])
                    if rc is True:
                        nic = i['SecondENIId']
        return nic

    def verify_byol_licenses(self):
        if self.table is not None:
            try:
                results = self.table.query(TableName=self.table_name, KeyConditionExpression=Key('Type').eq(TYPE_BYOL_LICENSE))
            except self.db_client.exceptions.ResourceNotFoundException:
                logger.exception('no licenses found():')
                return
            if results is not None:
                for lf in results['Items']:
                    owner = lf['InstanceOwner']
                    if owner != 'unused':
                        logger.debug("verify_byol_license(1): Found Owner Instance = %s" % owner)
                        key = lf['TypeId']
                        bucket = lf['Bucket']
                        size = lf['Size']
                        if owner != 'unused':
                            instance_id_not_found = False
                            r = None
                            try:
                                r = self.ec2_client.describe_instance_status(InstanceIds=[owner])
                                logger.debug("verify_byol_licenses(20a): Found InService Instance = %s" % owner)
                            except ClientError as e:
                                if e.response['Error']['Code'] == 'InvalidInstanceID.NotFound':
                                    logger.exception('verify_byol_license EXCEPTION instance not found(): ')
                                    instance_id_not_found = True
                            if r is not None and 'InstanceStatuses' in r:
                                if len(r['InstanceStatuses']) > 0:
                                    state = r['InstanceStatuses'][0]['InstanceState']['Name']
                                    if state == 'terminated':
                                        instance_id_not_found = True
                                else:
                                    instance_id_not_found = True
                            if instance_id_not_found is True:
                                logger.info("verify_byol_license(): License unused and being returned to pool = %s" % key)
                                owner = "unused"
                                ldb = {"Type": TYPE_BYOL_LICENSE, "TypeId": key, "Bucket": bucket,
                                       "Size": size, "InstanceOwner": owner}
                                self.table.put_item(Item=ldb)

    def process_notification(self, data):
        if 'Message' not in data:
            return
        try:
            msg = json.loads(data['Message'])
        except ValueError:
            logger.exception('sns(): Notification Not Valid JSON: {}'.format(data['Message']))
            return HttpResponseBadRequest('Not Valid JSON')
        if 'Event' in msg and msg['Event'] == 'autoscaling:TEST_NOTIFICATION':
            logger.info('process_notification(): TEST_NOTIFICATION')
            return STATUS_OK
        if 'LifecycleTransition' in msg and msg['LifecycleTransition'] == 'autoscaling:EC2_INSTANCE_LAUNCHING':
            logger.info('process_notification(): LCH_LAUNCH - instance = %s' % msg['EC2InstanceId'])
            return self.lch_launch(data)
        if 'LifecycleTransition' in msg and msg['LifecycleTransition'] == 'autoscaling:EC2_INSTANCE_TERMINATING':
            logger.info('process_notification(): LCH_TERMINATE - instance = %s' % msg['EC2InstanceId'])
            return self.lch_terminate(data)
        if 'Event' in msg and msg['Event'] == 'autoscaling:EC2_INSTANCE_LAUNCH':
            logger.info('process_notification(): EC2_LAUNCH - instance = %s' % msg['EC2InstanceId'])
            return self.launch_instance(data)
        if 'Event' in msg and msg['Event'] == 'autoscaling:EC2_INSTANCE_TERMINATE':
            logger.info('process_notification(): EC2_TERMINATE - instance = %s' % msg['EC2InstanceId'])
            return self.terminate_instance(data)

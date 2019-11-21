from .const import *


class RouteTable(object):
    def __init__(self, asg, subnet):
        self.asg = asg
        self.route_table_id = None
        self.subnet_id = None
        self.eni = None
        f = [{'Name': 'association.subnet-id', 'Values': [subnet]}]
        routes = asg.ec2_client.describe_route_tables(Filters=f)
        for rt in routes['RouteTables']:
            for r in rt['Routes']:
                if 'DestinationCidrBlock' in r and r['DestinationCidrBlock'] == '0.0.0.0/0':
                    self.route_table_id = rt['RouteTableId']
                    self.subnet_id = subnet
                    if 'NetworkInterfaceId' in r:
                        self.eni = r['NetworkInterfaceId']

    def write_to_db(self):
        rt = {"Type": TYPE_ROUTETABLE_ID, "TypeId": self.route_table_id, "Subnet": self.subnet_id}
        if self.eni is not None:
            rt.update({"NetworkInterfaceId": self.eni})
        self.asg.table.put_item(Item=rt)

    def __repr__(self):
        return ' () ' % ()

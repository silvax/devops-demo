#! /usr/bin/env python

from pynamodb.models import Model
from pynamodb.attributes import UnicodeAttribute, BooleanAttribute, NumberAttribute
import yaml,argparse
from collections import OrderedDict

sudo_users = {}
ssh_users = []
ssh_users_details = OrderedDict()

# Parse command line arguments
parser = argparse.ArgumentParser(description='Process command line arguments')
parser.add_argument('-t', '--table', nargs='*',dest='table', action="store", default='ssh-user', required=False, help='Enter the name of the DynamoDB tables where data is stored. Default is ssh_users')
parser.add_argument('-r', '--region', nargs='*',dest='region', action="store", default='us-east-1', required=False, help='Enter the AWS region where the DynamoDB table is stored. Default is us-east-1')
parser.add_argument('-f', '--file', nargs='*',dest='file', action="store", default='/opt/gatekeeper/user.yml', required=False, help='enter the name of the yaml file where the data will be stored. Default is users.yml')
args = parser.parse_args()


# Added to be able to a yaml.dump with an ordered dict
def represent_odict(dump, tag, mapping, flow_style=None):
    """Like BaseRepresenter.represent_mapping, but does not issue the sort().
    """
    value = []
    node = yaml.MappingNode(tag, value, flow_style=flow_style)
    if dump.alias_key is not None:
        dump.represented_objects[dump.alias_key] = node
    best_style = True
    if hasattr(mapping, 'items'):
        mapping = mapping.items()
    for item_key, item_value in mapping:
        node_key = dump.represent_data(item_key)
        node_value = dump.represent_data(item_value)
        if not (isinstance(node_key, yaml.ScalarNode) and not node_key.style):
            best_style = False
        if not (isinstance(node_value, yaml.ScalarNode) and not node_value.style):
            best_style = False
        value.append((node_key, node_value))
    if flow_style is None:
        if dump.default_flow_style is not None:
            node.flow_style = dump.default_flow_style
        else:
            node.flow_style = best_style
    return node

# This model defines the table that pynamodb reads fro DynamoDB
class UserModel(Model):
    """
    A DynamoDB SSH User Table
    """
    class Meta:
        table_name = args.table
        region = args.region
    username = UnicodeAttribute(hash_key=True )
    userstate = UnicodeAttribute()
    ssh_key = UnicodeAttribute()
    uid = NumberAttribute()

# This section of code reads the dynamobdb table and loads the data into an ordered dictionary
print "Reading users from DynamoDB ..."
for user in  UserModel.scan():
    ssh_users_details['name']= user.username
    ssh_users_details['userstate']=user.userstate
    ssh_users_details['ssh_key']=user.ssh_key
    ssh_users_details['uid']=user.uid
    ssh_users.append(ssh_users_details)
    ssh_users_details = OrderedDict()


sudo_users['sudo_users']=ssh_users

#This allows for the ordered dicto to be dumped to yaml
yaml.SafeDumper.add_representer(OrderedDict,
    lambda dumper, value: represent_odict(dumper, u'tag:yaml.org,2002:map', value))

# this will write the data in the ordered dictionary into the yaml file
print "Writing YAML file with users ..."
with open(args.file, 'w') as outfile:
    outfile.write(yaml.safe_dump(sudo_users, default_flow_style=False) )

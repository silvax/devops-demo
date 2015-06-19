#! /usr/bin/env python
from boto.sts import STSConnection
import boto.dynamodb2
from boto.dynamodb2.table import Table
import yaml,argparse
from collections import OrderedDict

sudo_users = {}
ssh_users = []
ssh_users_details = OrderedDict()
dest_role = "arn:aws:iam::607886752321:role/gatekeeper"

# Parse command line arguments
parser = argparse.ArgumentParser(description='Process command line arguments')
parser.add_argument('-t', '--table', dest='table', action="store", default='ssh-user', required=True, help='Enter the name of the DynamoDB tables where data is stored. Default is ssh_users')
parser.add_argument('-r', '--region', dest='region', action="store", required=True, help='Enter the AWS region where the DynamoDB table is stored. Default is us-east-1')
parser.add_argument('-f', '--file', dest='file', action="store",required=True, help='enter the name of the yaml file where the data will be stored. Default is users.yml')
parser.add_argument('-s', '--stsrole', dest='stsrole', action="store", required=False, help='enter the arn of the role that will be assumed on the target account for dynamodb accessl')

args = parser.parse_args()


if args.stsrole:
    sts_connection = STSConnection()
    assumedRoleObject = sts_connection.assume_role(
        role_arn=args.stsrole,
        role_session_name="AssumeRoleSession1"
    )
    print "setting up STS connection with assumed role: " + args.stsrole

    # create the connection using sts
    conn = boto.dynamodb2.connect_to_region(
        args.region,
        aws_access_key_id=assumedRoleObject.credentials.access_key,
        aws_secret_access_key=assumedRoleObject.credentials.secret_key,
        security_token=assumedRoleObject.credentials.session_token
    )
else:
    # create the connection no sts
    conn = boto.dynamodb2.connect_to_region(
        args.region
    )


ssh_user_table = Table(args.table, connection=conn)


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


# This section of code reads the dynamobdb table and loads the data into an ordered dictionary
print "Reading users from DynamoDB Table :" + args.table
for user in ssh_user_table.scan():
    ssh_users_details['name']= user['username']
    ssh_users_details['userstate']=user['userstate']
    ssh_users_details['ssh_key']=user['ssh_key']
    ssh_users.append(ssh_users_details)
    ssh_users_details = OrderedDict()

sudo_users['sudo_users']=ssh_users

#This allows for the ordered dicto to be dumped to yaml
yaml.SafeDumper.add_representer(OrderedDict,
    lambda dumper, value: represent_odict(dumper, u'tag:yaml.org,2002:map', value))

# this will write the data in the ordered dictionary into the yaml file
print "Writing YAML file with users to file: " + args.file
with open(args.file, 'w') as outfile:
    outfile.write(yaml.safe_dump(sudo_users, default_flow_style=False) )

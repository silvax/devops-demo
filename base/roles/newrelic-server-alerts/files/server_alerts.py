import requests
import requests.auth
import requests.exceptions
import argparse
import datetime
import json


def make_api_uri(path):
    return'https://api.newrelic.com/v2/{}'.format(path)

def make_headers(api_key):
    return {'X-Api-Key': api_key, 'Content-Type':'application/json'}

def get(path, api_key, params=None):
    result = requests.get(make_api_uri(path), headers=make_headers(api_key), params=params)
    result.raise_for_status()
    return result.json()

def put(path, api_key, data=None):
    result = requests.put(make_api_uri(path), headers=make_headers(api_key), data=data)
    result.raise_for_status()
    return result.json()

def is_active(server):
    reporting = server['reporting']
    last = datetime.datetime.strptime(server['last_reported_at'], "%Y-%m-%dT%H:%M:%S+00:00")
    age = datetime.datetime.utcnow() - last
    return reporting or age < datetime.timedelta(minutes=30)

def get_server_policy(api_key, policy_name):
    policies = get('alert_policies.json', api_key, params={'filter[name]':policy_name, 'filter[type]':'server'})
    policies = [x for x in policies['alert_policies'] if x['name'] == policy_name]
    if len(policies) == 1:
        return policies[0]
    else:
        return None

def main():
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--api-key', help='New Relic API key.', required=True)
    parser.add_argument('--role', help='Role label for the servers', required=True)
    parser.add_argument('--policy', help='Server alert policy for the servers')

    args = parser.parse_args()

    api_key = args.api_key
    role = args.role
    policy_name = args.policy

    if policy_name is None:
        policy_name = role

    result = get('servers.json', api_key, {'filter[labels]':'Role:%s'%role})
    active = [x['id'] for x in result['servers'] if is_active(x)]

    policy = get_server_policy(api_key, policy_name)

    if policy is not None:
        data = {'alert_policy': {'links': {'servers': active}}}
        put('alert_policies/%s.json'%policy['id'], api_key, data=json.dumps(data))
        print "Added servers %s to server alert policy %s"%(active, policy['id'])
    else:
        print "Error: did not find server alert policy: %s"%policy_name

if __name__ == '__main__':
    main()

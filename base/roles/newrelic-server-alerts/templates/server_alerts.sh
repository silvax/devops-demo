#!/usr/bin/env bash

# /etc/newrelic/api_key is written out by newrelic-configure
API_KEY=`cat /etc/newrelic/api_key`

# set the alert policy list to the active servers
{% if newrelic_server_alert_policy is defined %}
python /opt/newrelic_server_alerts/server_alerts.py --api-key $API_KEY --role {{ service_role }} --policy {{ newrelic_server_alert_policy }}
{% else %}
python /opt/newrelic_server_alerts/server_alerts.py --api-key $API_KEY --role {{ service_role }} --policy {{ service_role }}
{% endif %}


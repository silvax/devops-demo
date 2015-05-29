#!/usr/bin/env bash

# set the alert policy list to the active servers
{% if newrelic_server_alert_policy is defined %}
python /opt/newrelic_server_alerts/server_alerts.py --api-key {{ newrelic_api_key }} --role {{ service_role }} --policy {{ newrelic_server_alert_policy }}
{% else %}
python /opt/newrelic_server_alerts/server_alerts.py --api-key {{ newrelic_api_key }} --role {{ service_role }} --policy {{ service_role }}
{% endif %}


#!/bin/bash

# Wazuh Integration Wrapper for Slack Alerts
INTEGRATION_DIR="/home/scott/docker/wazuh-slack-integration"
source "$INTEGRATION_DIR/.env"

# Read alert from stdin
ALERT_DATA=$(cat)

# Log for debugging
echo "$(date): Processing alert" >> "$INTEGRATION_DIR/wazuh-alerts.log"

# Send to Slack
echo "$ALERT_DATA" | python3 "$INTEGRATION_DIR/slack-integration.py" \
    --webhook-url "$SLACK_WEBHOOK_URL" \
    --min-level 7 >> "$INTEGRATION_DIR/wazuh-alerts.log" 2>&1

exit 0

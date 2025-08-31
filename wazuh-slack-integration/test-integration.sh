#!/bin/bash

INTEGRATION_DIR="/home/scott/docker/wazuh-slack-integration"
source "$INTEGRATION_DIR/.env"

echo "Testing Slack integration..."

# Test with a sample Wazuh alert
cat << 'JSON' | python3 "$INTEGRATION_DIR/slack-integration.py" --webhook-url "$SLACK_WEBHOOK_URL"
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "rule": {
    "level": 8,
    "description": "SSH authentication failure from external IP",
    "id": "5716",
    "groups": ["authentication", "ssh", "failed"]
  },
  "agent": {
    "name": "homelab-server",
    "ip": "192.168.1.100"
  },
  "data": {
    "srcip": "203.0.113.10",
    "user": "admin",
    "port": "22"
  }
}
JSON

echo "Test alert sent! Check your Slack channel."

#!/bin/bash

# Simplified Wazuh Slack Integration Installation
# Works with existing Wazuh Docker setup

set -e

INTEGRATION_DIR="/home/scott/docker/wazuh-slack-integration"
WAZUH_CONFIG_DIR="/opt/wazuh-docker/config/wazuh_cluster"
LOG_FILE="$INTEGRATION_DIR/installation.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting simplified Slack integration setup..."

# Source webhook URL
source "$INTEGRATION_DIR/.env"

# Create integration script in our directory (no sudo needed)
log "Creating integration wrapper script..."

cat > "$INTEGRATION_DIR/wazuh-wrapper.sh" << 'EOF'
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
EOF

chmod +x "$INTEGRATION_DIR/wazuh-wrapper.sh"

# Create test script
log "Creating test script..."
cat > "$INTEGRATION_DIR/test-integration.sh" << 'EOF'
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
EOF

chmod +x "$INTEGRATION_DIR/test-integration.sh"

# Show manual configuration steps
log "Manual configuration required:"
log "================================"
log "1. You need to manually add integration to Wazuh configuration"
log "2. Copy and paste this into /opt/wazuh-docker/config/wazuh_cluster/wazuh_manager.conf"
log "   (before the closing </ossec_config> tag):"
log ""
cat << 'CONFIG'
  <!-- Slack Integration for Security Alerts -->
  <integration>
    <name>slack</name>
    <hook_url>https://hooks.slack.com/services/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</hook_url>
    <level>7</level>
    <group>authentication_failed,web,attacks,suricata,malware</group>
    <api_key>wazuh-slack</api_key>
    <alert_format>json</alert_format>
  </integration>

  <!-- High Priority Alerts -->
  <integration>
    <name>slack</name>
    <hook_url>https://hooks.slack.com/services/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</hook_url>
    <level>10</level>
    <api_key>wazuh-slack-high</api_key>
    <alert_format>json</alert_format>
  </integration>

  <!-- Critical Alerts -->
  <integration>
    <name>slack</name>
    <hook_url>https://hooks.slack.com/services/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</hook_url>
    <level>12</level>
    <api_key>wazuh-slack-critical</api_key>
    <alert_format>json</alert_format>
  </integration>
CONFIG

log ""
log "3. After adding the configuration, restart Wazuh manager:"
log "   cd /opt/wazuh-docker && docker-compose restart wazuh.manager"
log ""
log "4. Test the integration:"
log "   $INTEGRATION_DIR/test-integration.sh"

# Run immediate test
log ""
log "Running test now..."
"$INTEGRATION_DIR/test-integration.sh"

log "Setup completed! Manual configuration steps above are required."
EOF
#!/bin/bash

# Wazuh Slack Integration Installation Script
# Configures Wazuh manager to send alerts to Slack

set -e

INTEGRATION_DIR="/home/scott/docker/wazuh-slack-integration"
WAZUH_CONFIG_DIR="/opt/wazuh-docker/config/wazuh_cluster"
WAZUH_INTEGRATIONS_DIR="$WAZUH_CONFIG_DIR/integrations"
LOG_FILE="$INTEGRATION_DIR/installation.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

log "Starting Wazuh Slack integration installation..."

# Check if Wazuh is installed
if [ ! -d "$WAZUH_CONFIG_DIR" ]; then
    error "Wazuh configuration directory not found at $WAZUH_CONFIG_DIR"
    exit 1
fi

# Check if webhook URL is configured
if [ ! -f "$INTEGRATION_DIR/.env" ]; then
    error "Environment file with webhook URL not found"
    exit 1
fi

source "$INTEGRATION_DIR/.env"
if [ -z "$SLACK_WEBHOOK_URL" ]; then
    error "SLACK_WEBHOOK_URL not set in .env file"
    exit 1
fi

# Install Python dependencies
log "Installing Python dependencies..."
if command -v pip3 &> /dev/null; then
    pip3 install requests
else
    error "pip3 not found. Please install Python3 and pip3"
    exit 1
fi

# Create integrations directory structure
log "Creating Wazuh integrations directory..."
sudo mkdir -p "$WAZUH_INTEGRATIONS_DIR"

# Create custom Slack integration script for Wazuh
log "Creating Wazuh integration scripts..."

# Create the main integration script that Wazuh will call
sudo tee "$WAZUH_INTEGRATIONS_DIR/custom-slack" << 'EOF'
#!/bin/bash

# Wazuh Custom Slack Integration Wrapper
# This script is called by Wazuh manager for each alert

INTEGRATION_DIR="/home/scott/docker/wazuh-slack-integration"
LOG_FILE="$INTEGRATION_DIR/wazuh-slack.log"

# Source environment variables
source "$INTEGRATION_DIR/.env"

# Get the alert data from Wazuh (passed via stdin)
ALERT_DATA=$(cat)

# Log the alert for debugging
echo "$(date): Processing alert" >> "$LOG_FILE"
echo "$ALERT_DATA" | python3 -m json.tool >> "$LOG_FILE" 2>/dev/null || echo "$ALERT_DATA" >> "$LOG_FILE"

# Send to our Python script
echo "$ALERT_DATA" | python3 "$INTEGRATION_DIR/slack-integration.py" \
    --webhook-url "$SLACK_WEBHOOK_URL" \
    --min-level 7 >> "$LOG_FILE" 2>&1

# Exit with success to prevent Wazuh from retrying
exit 0
EOF

# Create high priority integration script
sudo tee "$WAZUH_INTEGRATIONS_DIR/custom-slack-high" << 'EOF'
#!/bin/bash

INTEGRATION_DIR="/home/scott/docker/wazuh-slack-integration"
source "$INTEGRATION_DIR/.env"

ALERT_DATA=$(cat)
echo "$(date): Processing HIGH priority alert" >> "$INTEGRATION_DIR/wazuh-slack.log"

echo "$ALERT_DATA" | python3 "$INTEGRATION_DIR/slack-integration.py" \
    --webhook-url "$SLACK_WEBHOOK_URL" \
    --min-level 10 >> "$INTEGRATION_DIR/wazuh-slack.log" 2>&1

exit 0
EOF

# Create critical priority integration script  
sudo tee "$WAZUH_INTEGRATIONS_DIR/custom-slack-critical" << 'EOF'
#!/bin/bash

INTEGRATION_DIR="/home/scott/docker/wazuh-slack-integration"
source "$INTEGRATION_DIR/.env"

ALERT_DATA=$(cat)
echo "$(date): Processing CRITICAL priority alert" >> "$INTEGRATION_DIR/wazuh-slack.log"

echo "$ALERT_DATA" | python3 "$INTEGRATION_DIR/slack-integration.py" \
    --webhook-url "$SLACK_WEBHOOK_URL" \
    --min-level 12 >> "$INTEGRATION_DIR/wazuh-slack.log" 2>&1

exit 0
EOF

# Create Suricata-specific integration script
sudo tee "$WAZUH_INTEGRATIONS_DIR/custom-slack-suricata" << 'EOF'
#!/bin/bash

INTEGRATION_DIR="/home/scott/docker/wazuh-slack-integration"
source "$INTEGRATION_DIR/.env"

ALERT_DATA=$(cat)
echo "$(date): Processing SURICATA alert" >> "$INTEGRATION_DIR/wazuh-slack.log"

echo "$ALERT_DATA" | python3 "$INTEGRATION_DIR/slack-integration.py" \
    --webhook-url "$SLACK_WEBHOOK_URL" \
    --min-level 7 >> "$INTEGRATION_DIR/wazuh-slack.log" 2>&1

exit 0
EOF

# Make integration scripts executable
sudo chmod +x "$WAZUH_INTEGRATIONS_DIR"/custom-slack*

# Set proper ownership
sudo chown -R 999:999 "$WAZUH_INTEGRATIONS_DIR"

log "Adding integration configuration to Wazuh manager..."

# Backup existing configuration
if [ -f "$WAZUH_CONFIG_DIR/wazuh_manager.conf" ]; then
    sudo cp "$WAZUH_CONFIG_DIR/wazuh_manager.conf" "$WAZUH_CONFIG_DIR/wazuh_manager.conf.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Check if Slack integration is already configured
if grep -q "custom-slack" "$WAZUH_CONFIG_DIR/wazuh_manager.conf" 2>/dev/null; then
    warn "Slack integration already configured in wazuh_manager.conf"
else
    log "Adding Slack integration configuration..."
    
    # Add integration configuration before closing </ossec_config>
    sudo sed -i '/<\/ossec_config>/i\
\
  <!-- Slack Integration for Security Alerts -->\
  <integration>\
    <name>custom-slack</name>\
    <level>7</level>\
    <group>authentication_success,authentication_failed,connection_attempt,attacks</group>\
    <api_key>slack</api_key>\
    <alert_format>json</alert_format>\
  </integration>\
\
  <integration>\
    <name>custom-slack-high</name>\
    <level>10</level>\
    <api_key>slack-high</api_key>\
    <alert_format>json</alert_format>\
  </integration>\
\
  <integration>\
    <name>custom-slack-critical</name>\
    <level>12</level>\
    <api_key>slack-critical</api_key>\
    <alert_format>json</alert_format>\
  </integration>\
\
  <integration>\
    <name>custom-slack-suricata</name>\
    <level>7</level>\
    <group>suricata,intrusion_detection,ids</group>\
    <api_key>slack-suricata</api_key>\
    <alert_format>json</alert_format>\
  </integration>\
' "$WAZUH_CONFIG_DIR/wazuh_manager.conf"

    log "Integration configuration added to wazuh_manager.conf"
fi

# Create test alert script
log "Creating test alert script..."
cat > "$INTEGRATION_DIR/test-alerts.sh" << 'EOF'
#!/bin/bash

echo "Testing Slack integration with sample alerts..."

# Test different severity levels
INTEGRATION_DIR="/home/scott/docker/wazuh-slack-integration"
source "$INTEGRATION_DIR/.env"

# Test Level 7 - Medium Priority
echo "Testing Level 7 (Medium Priority) Alert..."
cat << 'JSON' | python3 "$INTEGRATION_DIR/slack-integration.py" --webhook-url "$SLACK_WEBHOOK_URL"
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "rule": {
    "level": 7,
    "description": "SSH authentication failure",
    "id": "5716",
    "groups": ["authentication", "ssh"]
  },
  "agent": {
    "name": "proxmox-host",
    "ip": "192.168.1.100"
  },
  "data": {
    "srcip": "192.168.1.50",
    "user": "admin"
  }
}
JSON

sleep 2

# Test Level 10 - High Priority
echo "Testing Level 10 (High Priority) Alert..."
cat << 'JSON' | python3 "$INTEGRATION_DIR/slack-integration.py" --webhook-url "$SLACK_WEBHOOK_URL"
{
  "timestamp": "2024-01-15T10:31:00.000Z",
  "rule": {
    "level": 10,
    "description": "Suricata: Malware detected in network traffic",
    "id": "200010",
    "groups": ["suricata", "malware", "trojan"]
  },
  "agent": {
    "name": "docker-host",
    "ip": "192.168.1.101"
  },
  "data": {
    "srcip": "10.0.0.50",
    "dstip": "8.8.8.8"
  }
}
JSON

sleep 2

# Test Level 12 - Critical Priority
echo "Testing Level 12 (Critical Priority) Alert..."
cat << 'JSON' | python3 "$INTEGRATION_DIR/slack-integration.py" --webhook-url "$SLACK_WEBHOOK_URL"
{
  "timestamp": "2024-01-15T10:32:00.000Z",
  "rule": {
    "level": 12,
    "description": "Multiple authentication failures followed by successful login",
    "id": "40111",
    "groups": ["authentication", "privilege_escalation"]
  },
  "agent": {
    "name": "manjaro-vm",
    "ip": "192.168.1.102"
  },
  "data": {
    "srcip": "203.0.113.10",
    "user": "root"
  }
}
JSON

echo "Test alerts sent! Check your Slack channel."
EOF

chmod +x "$INTEGRATION_DIR/test-alerts.sh"

# Create monitoring script
log "Creating monitoring script..."
cat > "$INTEGRATION_DIR/monitor-slack-integration.sh" << 'EOF'
#!/bin/bash

INTEGRATION_DIR="/home/scott/docker/wazuh-slack-integration"
LOG_FILE="$INTEGRATION_DIR/wazuh-slack.log"

echo "=== Slack Integration Status ==="
echo "Last 10 alerts processed:"
echo

if [ -f "$LOG_FILE" ]; then
    tail -20 "$LOG_FILE" | grep "Processing" | tail -10
    echo
    echo "Recent errors (if any):"
    tail -50 "$LOG_FILE" | grep -i error | tail -5
    echo
    echo "Log file size: $(du -h $LOG_FILE | cut -f1)"
else
    echo "No log file found yet - no alerts have been processed"
fi

echo
echo "Integration scripts:"
ls -la /opt/wazuh-docker/config/wazuh_cluster/integrations/custom-slack* 2>/dev/null || echo "Integration scripts not found"

echo
echo "Wazuh manager status:"
docker ps --filter name=wazuh.manager --format "table {{.Names}}\t{{.Status}}"
EOF

chmod +x "$INTEGRATION_DIR/monitor-slack-integration.sh"

# Restart Wazuh manager to apply configuration
log "Restarting Wazuh manager to apply new integration..."
cd /opt/wazuh-docker
if docker-compose restart wazuh.manager; then
    log "Wazuh manager restarted successfully"
else
    warn "Failed to restart Wazuh manager - you may need to restart manually"
fi

log "Waiting for Wazuh manager to fully initialize..."
sleep 30

# Run test alerts
log "Running test alerts to verify integration..."
"$INTEGRATION_DIR/test-alerts.sh"

log "Installation completed successfully!"
log
log "Summary:"
log "========"
log "• Slack webhook configured: ✅"
log "• Integration scripts installed: ✅"
log "• Wazuh configuration updated: ✅"
log "• Test alerts sent: ✅"
log
log "Useful commands:"
log "• Test integration: $INTEGRATION_DIR/test-alerts.sh"
log "• Monitor alerts: $INTEGRATION_DIR/monitor-slack-integration.sh"
log "• View logs: tail -f $INTEGRATION_DIR/wazuh-slack.log"
log "• Test single alert: python3 $INTEGRATION_DIR/slack-integration.py --test"
log
log "Check your Slack channel for the test alerts!"
EOF
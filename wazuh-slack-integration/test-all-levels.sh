#!/bin/bash

# Test Slack integration with different alert severity levels

INTEGRATION_DIR="/home/scott/docker/wazuh-slack-integration"
source "$INTEGRATION_DIR/.env"

echo "🔒 Testing Wazuh Slack Integration with Different Alert Levels"
echo "=============================================================="
echo

sleep 2

echo "📊 Testing Level 7 (Medium Priority) - SSH Authentication Failure"
cat << 'JSON' | python3 "$INTEGRATION_DIR/slack-integration.py" --webhook-url "$SLACK_WEBHOOK_URL"
{
  "timestamp": "2025-08-31T14:30:00.000Z",
  "rule": {
    "level": 7,
    "description": "SSH authentication failure from suspicious IP",
    "id": "5716",
    "groups": ["authentication_failed", "ssh"]
  },
  "agent": {
    "name": "proxmox-host",
    "ip": "192.168.1.100"
  },
  "data": {
    "srcip": "203.0.113.10",
    "user": "root",
    "port": "22"
  }
}
JSON

sleep 3

echo "⚠️  Testing Level 10 (High Priority) - Suricata Malware Detection"
cat << 'JSON' | python3 "$INTEGRATION_DIR/slack-integration.py" --webhook-url "$SLACK_WEBHOOK_URL"
{
  "timestamp": "2025-08-31T14:31:00.000Z",
  "rule": {
    "level": 10,
    "description": "Suricata: Malware detected in network traffic - Trojan.Generic",
    "id": "200010",
    "groups": ["suricata", "malware", "trojan", "intrusion_detection"]
  },
  "agent": {
    "name": "docker-host",
    "ip": "192.168.1.101"
  },
  "data": {
    "srcip": "10.0.0.50",
    "dstip": "8.8.8.8",
    "proto": "TCP",
    "signature": "ET TROJAN Suspicious TCP Packet"
  }
}
JSON

sleep 3

echo "🚨 Testing Level 12 (Critical Priority) - Privilege Escalation"
cat << 'JSON' | python3 "$INTEGRATION_DIR/slack-integration.py" --webhook-url "$SLACK_WEBHOOK_URL"
{
  "timestamp": "2025-08-31T14:32:00.000Z",
  "rule": {
    "level": 12,
    "description": "Successful administrator privilege gain after multiple failures",
    "id": "40111",
    "groups": ["authentication", "privilege_escalation", "successful_admin"]
  },
  "agent": {
    "name": "manjaro-vm",
    "ip": "192.168.1.102"
  },
  "data": {
    "srcip": "203.0.113.15",
    "user": "root",
    "previous_failures": "15"
  }
}
JSON

sleep 3

echo "🌐 Testing Level 8 - Web Application Attack"
cat << 'JSON' | python3 "$INTEGRATION_DIR/slack-integration.py" --webhook-url "$SLACK_WEBHOOK_URL"
{
  "timestamp": "2025-08-31T14:33:00.000Z",
  "rule": {
    "level": 8,
    "description": "SQL injection attack attempt detected",
    "id": "31151",
    "groups": ["web", "attacks", "web_application_attack"]
  },
  "agent": {
    "name": "docker-host",
    "ip": "192.168.1.101"
  },
  "data": {
    "srcip": "192.168.1.50",
    "url": "/login.php",
    "method": "POST",
    "payload": "admin' OR '1'='1"
  }
}
JSON

sleep 3

echo "🔍 Testing Level 9 - DNS Security Alert"
cat << 'JSON' | python3 "$INTEGRATION_DIR/slack-integration.py" --webhook-url "$SLACK_WEBHOOK_URL"
{
  "timestamp": "2025-08-31T14:34:00.000Z",
  "rule": {
    "level": 9,
    "description": "DNS query to known malicious domain - C2 communication",
    "id": "200022",
    "groups": ["dns", "c2", "command_control", "malware"]
  },
  "agent": {
    "name": "pihole-dns",
    "ip": "192.168.1.103"
  },
  "data": {
    "query": "malicious-c2-server.tk",
    "client_ip": "192.168.1.75",
    "query_type": "A"
  }
}
JSON

sleep 3

echo "🐳 Testing Level 11 - Container Security Violation"
cat << 'JSON' | python3 "$INTEGRATION_DIR/slack-integration.py" --webhook-url "$SLACK_WEBHOOK_URL"
{
  "timestamp": "2025-08-31T14:35:00.000Z",
  "rule": {
    "level": 11,
    "description": "Container breakout attempt detected - Docker socket access",
    "id": "200101",
    "groups": ["container_security", "docker", "privilege_escalation"]
  },
  "agent": {
    "name": "docker-host",
    "ip": "192.168.1.101"
  },
  "data": {
    "container_id": "abc123def456",
    "process": "/usr/bin/docker",
    "file": "/var/run/docker.sock"
  }
}
JSON

echo
echo "✅ All test alerts sent!"
echo "📱 Check your Slack #security-alerts channel for the formatted notifications"
echo "🔧 You can customize alert levels and formatting in:"
echo "   - $INTEGRATION_DIR/slack-integration.py"
echo "   - $INTEGRATION_DIR/alert-filters.json"
echo
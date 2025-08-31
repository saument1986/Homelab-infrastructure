#!/usr/bin/env python3
"""
Wazuh Slack Integration Script
Sends formatted security alerts to Slack channels based on severity levels
"""

import json
import sys
import os
import requests
import argparse
from datetime import datetime
import logging

# Configuration
SLACK_WEBHOOK_URL = os.environ.get('SLACK_WEBHOOK_URL', '')
LOG_FILE = '/home/scott/docker/wazuh-slack-integration/slack-alerts.log'

# Set up logging
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Alert severity mappings
SEVERITY_LEVELS = {
    # Critical alerts (12+) - Red, immediate attention
    'critical': {
        'min_level': 12,
        'color': '#FF0000',
        'emoji': '🚨',
        'priority': 'HIGH',
        'mention': '@channel'
    },
    # High alerts (10-11) - Orange, urgent
    'high': {
        'min_level': 10,
        'color': '#FF8C00',
        'emoji': '⚠️',
        'priority': 'HIGH',
        'mention': '@here'
    },
    # Medium alerts (7-9) - Yellow, monitor
    'medium': {
        'min_level': 7,
        'color': '#FFD700',
        'emoji': '⚡',
        'priority': 'MEDIUM',
        'mention': ''
    },
    # Low alerts (5-6) - Blue, informational
    'low': {
        'min_level': 5,
        'color': '#4169E1',
        'emoji': 'ℹ️',
        'priority': 'LOW',
        'mention': ''
    }
}

# Rule group to category mapping
CATEGORY_MAPPING = {
    'suricata': '🌐 Network Security',
    'intrusion_detection': '🛡️ Intrusion Detection',
    'web_attack': '🌐 Web Attack',
    'malware': '🦠 Malware',
    'trojan': '🐎 Trojan Activity',
    'dns': '🔍 DNS Security',
    'ssh': '🔐 SSH Activity',
    'authentication': '🔑 Authentication',
    'privilege_escalation': '⬆️ Privilege Escalation',
    'lateral_movement': '↔️ Lateral Movement',
    'data_exfiltration': '📤 Data Exfiltration',
    'crypto_mining': '⛏️ Crypto Mining',
    'c2': '📡 Command & Control',
    'container_security': '🐳 Container Security',
    'vulnerability': '🔓 Vulnerability',
    'pihole': '🕳️ Pi-hole DNS',
    'nessus': '🔍 Vulnerability Scan'
}

def get_alert_severity(level):
    """Determine alert severity based on Wazuh rule level"""
    for severity, config in SEVERITY_LEVELS.items():
        if level >= config['min_level']:
            return severity, config
    return 'low', SEVERITY_LEVELS['low']

def get_category_icon(groups):
    """Get appropriate icon based on rule groups"""
    if not groups:
        return '🔒'
    
    groups_str = ','.join(groups).lower()
    for group, icon in CATEGORY_MAPPING.items():
        if group in groups_str:
            return icon.split()[0]  # Return just the emoji
    return '🔒'

def format_alert_message(alert_data):
    """Format Wazuh alert for Slack"""
    try:
        # Parse alert data
        timestamp = alert_data.get('timestamp', datetime.now().isoformat())
        rule = alert_data.get('rule', {})
        agent = alert_data.get('agent', {})
        
        level = rule.get('level', 0)
        description = rule.get('description', 'Security Alert')
        rule_id = rule.get('id', 'N/A')
        groups = rule.get('groups', [])
        
        agent_name = agent.get('name', 'Unknown')
        agent_ip = agent.get('ip', 'N/A')
        
        # Additional data
        src_ip = alert_data.get('data', {}).get('srcip', '')
        dst_ip = alert_data.get('data', {}).get('dstip', '')
        
        # Get severity configuration
        severity, severity_config = get_alert_severity(level)
        category_icon = get_category_icon(groups)
        
        # Format timestamp
        try:
            dt = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            formatted_time = dt.strftime('%Y-%m-%d %H:%M:%S UTC')
        except:
            formatted_time = timestamp
        
        # Build message
        emoji = severity_config['emoji']
        mention = severity_config['mention']
        
        # Create main message
        main_text = f"{emoji} *Wazuh Security Alert* - {severity_config['priority']} Priority"
        if mention:
            main_text = f"{mention} {main_text}"
        
        # Create attachment
        attachment = {
            "color": severity_config['color'],
            "fields": [
                {
                    "title": f"{category_icon} Alert Description",
                    "value": description,
                    "short": False
                },
                {
                    "title": "📊 Severity Level",
                    "value": f"Level {level} ({severity.upper()})",
                    "short": True
                },
                {
                    "title": "🆔 Rule ID",
                    "value": rule_id,
                    "short": True
                },
                {
                    "title": "🖥️ Agent",
                    "value": f"{agent_name} ({agent_ip})",
                    "short": True
                },
                {
                    "title": "🕒 Time",
                    "value": formatted_time,
                    "short": True
                }
            ],
            "footer": "Wazuh SIEM | Homelab Security",
            "footer_icon": "https://wazuh.com/assets/images/logos/wazuh.png",
            "ts": int(datetime.now().timestamp())
        }
        
        # Add network information if available
        if src_ip or dst_ip:
            network_info = ""
            if src_ip:
                network_info += f"Source: {src_ip}"
            if dst_ip:
                if network_info:
                    network_info += f" → Destination: {dst_ip}"
                else:
                    network_info += f"Destination: {dst_ip}"
            
            attachment["fields"].append({
                "title": "🌐 Network",
                "value": network_info,
                "short": True
            })
        
        # Add rule groups if available
        if groups:
            attachment["fields"].append({
                "title": "🏷️ Categories",
                "value": ", ".join(groups[:5]),  # Limit to first 5 groups
                "short": True
            })
        
        return {
            "text": main_text,
            "attachments": [attachment]
        }
        
    except Exception as e:
        logging.error(f"Error formatting alert: {e}")
        return {
            "text": f"🚨 Wazuh Alert (Formatting Error)",
            "attachments": [{
                "color": "#FF0000",
                "text": f"Error formatting alert: {str(e)}\nRaw data: {json.dumps(alert_data, indent=2)[:500]}..."
            }]
        }

def send_to_slack(message, webhook_url):
    """Send formatted message to Slack"""
    try:
        headers = {'Content-Type': 'application/json'}
        response = requests.post(webhook_url, json=message, headers=headers, timeout=10)
        
        if response.status_code == 200:
            logging.info("Alert sent to Slack successfully")
            return True
        else:
            logging.error(f"Slack API error: {response.status_code} - {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        logging.error(f"Network error sending to Slack: {e}")
        return False
    except Exception as e:
        logging.error(f"Unexpected error sending to Slack: {e}")
        return False

def should_send_alert(alert_data, min_level=7):
    """Determine if alert should be sent based on level and other criteria"""
    rule = alert_data.get('rule', {})
    level = rule.get('level', 0)
    groups = rule.get('groups', [])
    
    # Check minimum level
    if level < min_level:
        return False
    
    # Skip certain noisy rules (customize as needed)
    skip_groups = ['syscheck', 'rootcheck']  # Add groups to skip
    if any(skip_group in groups for skip_group in skip_groups):
        return False
    
    return True

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Send Wazuh alerts to Slack')
    parser.add_argument('--webhook-url', help='Slack webhook URL', default=SLACK_WEBHOOK_URL)
    parser.add_argument('--min-level', type=int, default=7, help='Minimum alert level to send (default: 7)')
    parser.add_argument('--test', action='store_true', help='Send test message')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')
    
    args = parser.parse_args()
    
    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Check webhook URL
    if not args.webhook_url:
        logging.error("No Slack webhook URL provided. Set SLACK_WEBHOOK_URL environment variable or use --webhook-url")
        sys.exit(1)
    
    # Send test message if requested
    if args.test:
        test_message = {
            "text": "🔒 Wazuh Slack Integration Test",
            "attachments": [{
                "color": "#00FF00",
                "fields": [
                    {"title": "Status", "value": "Integration Working ✅", "short": True},
                    {"title": "Time", "value": datetime.now().strftime('%Y-%m-%d %H:%M:%S'), "short": True}
                ]
            }]
        }
        
        if send_to_slack(test_message, args.webhook_url):
            print("✅ Test message sent successfully!")
            sys.exit(0)
        else:
            print("❌ Test message failed!")
            sys.exit(1)
    
    # Read alert data from stdin
    try:
        alert_json = sys.stdin.read().strip()
        if not alert_json:
            logging.error("No alert data provided via stdin")
            sys.exit(1)
        
        alert_data = json.loads(alert_json)
        logging.debug(f"Received alert data: {json.dumps(alert_data, indent=2)}")
        
    except json.JSONDecodeError as e:
        logging.error(f"Invalid JSON data: {e}")
        sys.exit(1)
    except Exception as e:
        logging.error(f"Error reading alert data: {e}")
        sys.exit(1)
    
    # Check if alert should be sent
    if not should_send_alert(alert_data, args.min_level):
        logging.info(f"Skipping alert (level {alert_data.get('rule', {}).get('level', 0)}) - below threshold")
        sys.exit(0)
    
    # Format and send alert
    message = format_alert_message(alert_data)
    
    if send_to_slack(message, args.webhook_url):
        logging.info("Alert processed and sent successfully")
        sys.exit(0)
    else:
        logging.error("Failed to send alert to Slack")
        sys.exit(1)

if __name__ == "__main__":
    main()
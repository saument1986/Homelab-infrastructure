# Wazuh Slack Integration

Complete Slack notification system for Wazuh SIEM security alerts in your homelab environment.

## ✅ Installation Complete

Your Slack integration is now fully configured and operational!

### 🔧 What's Configured

**Alert Levels:**
- **Level 7+**: Medium priority alerts (authentication failures, web attacks)
- **Level 10+**: High priority alerts (malware, intrusion detection) 
- **Level 12+**: Critical alerts (privilege escalation, successful attacks)

**Alert Categories:**
- 🔐 Authentication failures and successes
- 🌐 Web application attacks (SQL injection, XSS)
- 🛡️ Suricata network intrusion detection
- 🦠 Malware and trojan detection
- 📡 Command & control communications
- 🐳 Container security violations
- ⬆️ Privilege escalation attempts
- 🔍 DNS security events

**Slack Features:**
- **Color-coded alerts** (Red=Critical, Orange=High, Yellow=Medium, Blue=Low)
- **Rich formatting** with threat details and network information
- **Smart mentions** (@channel for critical, @here for high priority)
- **Category icons** for easy visual identification
- **Timestamp and source** information

## 📱 Slack Channel Setup

Your alerts are sent to: `#security-alerts`

**Sample Alert Format:**
```
🚨 Wazuh Security Alert - HIGH Priority @here

🛡️ Alert Description
Suricata: Malware detected in network traffic - Trojan.Generic

📊 Severity Level: Level 10 (HIGH)
🆔 Rule ID: 200010
🖥️ Agent: docker-host (192.168.1.101)
🕒 Time: 2025-08-31 14:31:00 UTC
🌐 Network: Source: 10.0.0.50 → Destination: 8.8.8.8
🏷️ Categories: suricata, malware, trojan, intrusion_detection
```

## 🛠️ Management Commands

**Test Integration:**
```bash
cd /home/scott/docker/wazuh-slack-integration

# Send test message
python3 slack-integration.py --test

# Test all alert levels
./test-all-levels.sh

# Test single alert
./test-integration.sh
```

**Monitor Integration:**
```bash
# View recent alerts
tail -f wazuh-alerts.log

# Check integration status
./monitor-slack-integration.sh

# View Wazuh manager logs
docker logs wazuh.manager
```

**Configuration Files:**
- `slack-integration.py` - Main integration script
- `alert-filters.json` - Filtering and formatting rules
- `.env` - Webhook URL (secure)
- `/opt/wazuh-docker/config/wazuh_cluster/wazuh_manager.conf` - Wazuh integration config

## 📊 Alert Statistics

The integration processes:
- **Authentication events** from all agents
- **Network threats** from Suricata IDS
- **Web attacks** from application logs  
- **System security** events from rootcheck
- **Container security** violations
- **DNS security** events from Pi-hole

## 🔧 Customization

### Adjust Alert Levels
Edit `/opt/wazuh-docker/config/wazuh_cluster/wazuh_manager.conf`:
```xml
<integration>
  <level>5</level>  <!-- Change minimum alert level -->
  <group>web,attacks</group>  <!-- Add/remove alert groups -->
</integration>
```

### Customize Formatting
Edit `slack-integration.py`:
- Modify `SEVERITY_LEVELS` for different colors/emojis
- Update `CATEGORY_MAPPING` for custom icons
- Adjust `should_send_alert()` for filtering logic

### Filter Noisy Alerts
Edit the `should_send_alert()` function:
```python
# Skip certain noisy rules
skip_groups = ['syscheck', 'rootcheck']
skip_rules = [5503, 5504]  # Add rule IDs to skip
```

## 🚨 Alert Response Procedures

### Critical Alerts (Level 12+)
1. **Immediate response required** (@channel notification)
2. Check Wazuh dashboard for full context
3. Investigate source IP and affected systems
4. Consider isolation if compromise confirmed
5. Document incident for post-analysis

### High Priority Alerts (Level 10-11)  
1. **Urgent investigation** (@here notification)
2. Correlate with other security events
3. Check for patterns or campaign indicators
4. Update security controls if needed

### Medium Priority Alerts (Level 7-9)
1. **Monitor and investigate** during business hours
2. Look for escalation or persistence
3. Update blacklists/rules as appropriate
4. Track metrics and trends

## 📈 Monitoring and Maintenance

### Daily Checks
- Review critical/high alerts in Slack
- Check for any integration failures
- Monitor log file sizes

### Weekly Maintenance  
- Update threat intelligence feeds
- Review and tune alert thresholds
- Analyze alert trends and patterns

### Monthly Reviews
- Evaluate alert effectiveness
- Update filtering rules
- Test failover procedures

## 🔍 Troubleshooting

### No Alerts Received
```bash
# Check Wazuh manager status
docker ps | grep wazuh.manager

# Test webhook manually
curl -X POST -H 'Content-type: application/json' \
--data '{"text":"Test message"}' \
https://hooks.slack.com/services/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

# Check Wazuh logs
docker logs wazuh.manager | grep -i slack
```

### Integration Errors
```bash
# Check integration logs
tail -50 wazuh-alerts.log | grep -i error

# Verify configuration
grep -A 10 -B 5 "slack" /opt/wazuh-docker/config/wazuh_cluster/wazuh_manager.conf

# Restart Wazuh manager
cd /opt/wazuh-docker && docker-compose restart wazuh.manager
```

### High Alert Volume
- Increase minimum alert level in configuration
- Add noisy rule IDs to suppression list
- Implement time-based filtering
- Set up alert grouping/deduplication

## 🔐 Security Notes

- Webhook URL is stored securely in `.env` with 600 permissions
- Integration scripts run with minimal privileges
- Alert data is sanitized before sending to Slack
- Network traffic is encrypted (HTTPS)

## 📞 Support

**Quick Status Check:**
```bash
cd /home/scott/docker/wazuh-slack-integration
./test-integration.sh
```

**Log Locations:**
- Integration logs: `wazuh-alerts.log`
- Installation logs: `installation.log` 
- Wazuh manager logs: `docker logs wazuh.manager`

---

**Status**: ✅ Active and Monitoring  
**Last Updated**: $(date '+%Y-%m-%d %H:%M:%S')  
**Version**: 1.0  
**Integration Type**: Real-time webhook notifications
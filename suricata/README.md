# Suricata IDS with Wazuh Integration

This directory contains a complete Suricata Intrusion Detection System (IDS) setup integrated with Wazuh SIEM for comprehensive network security monitoring in your homelab environment.

## Overview

Suricata is an open-source network threat detection engine that provides intrusion detection (IDS), intrusion prevention (IPS), and network security monitoring (NSM) capabilities. This implementation is specifically configured for homelab environments and integrates seamlessly with your existing Wazuh security stack.

## Features

- **Real-time Network Monitoring**: Monitors all network traffic on your specified interface
- **Advanced Threat Detection**: Uses Emerging Threats rules and custom homelab-specific rules
- **Wazuh SIEM Integration**: Forwards all alerts and events to Wazuh for centralized analysis
- **JSON Event Logging**: Structured logging for easy parsing and analysis
- **Automated Rule Updates**: Keeps threat signatures up to date
- **Performance Monitoring**: Built-in health checks and performance metrics
- **Container Security**: Monitors for container escape attempts and lateral movement

## Quick Start

### 1. Verify Prerequisites

```bash
# Ensure Docker and Docker Compose are installed
docker --version
docker-compose --version

# Check your network interface
ip addr show
```

### 2. Deploy Suricata

```bash
cd /home/scott/docker/suricata
./deploy-suricata.sh
```

This script will:
- Auto-detect your network interface
- Download the latest threat rules
- Configure Wazuh integration
- Start Suricata container
- Generate test traffic
- Verify the installation

### 3. Verify Installation

```bash
# Check container status
docker-compose ps

# View live alerts
tail -f logs/fast.log

# View JSON events
tail -f logs/eve.json | jq .

# Quick status check
./status.sh
```

## Configuration Files

### Core Configuration
- `docker-compose.yml` - Container orchestration
- `config/suricata.yaml` - Main Suricata configuration
- `config/classification.config` - Alert classification levels
- `config/reference.config` - Reference URL mappings
- `config/threshold.config` - Alert frequency control

### Rules
- `rules/suricata.rules` - Custom homelab-specific rules
- `rules/emerging-threats.rules` - Community threat signatures
- `update-rules.sh` - Automated rule update script

### Wazuh Integration
- `wazuh-integration/suricata_decoders.xml` - Log parsing rules for Wazuh
- `wazuh-integration/suricata_rules.xml` - Wazuh correlation rules
- `wazuh-integration/install-integration.sh` - Integration setup script

## Custom Security Rules

The configuration includes custom rules specifically designed for homelab environments:

### DNS Security
- Suspicious TLD monitoring (.tk, .ml, .ga, .cf)
- DNS tunneling detection
- Long TXT query analysis

### Web Application Security  
- SQL injection attempts
- XSS (Cross-Site Scripting) detection
- Directory traversal attempts

### Command & Control Detection
- C2 beacon identification
- Suspicious outbound connections
- Base64 encoded communications

### Container Security
- Docker socket access attempts
- Kubernetes API access monitoring
- Container breakout detection

### Cryptocurrency Mining
- Mining pool connections
- Browser-based mining scripts

### Lateral Movement
- SSH brute force attempts
- SMB admin share access
- Unusual authentication patterns

### Data Exfiltration
- Large outbound transfers
- DNS data exfiltration
- Unusual data patterns

## Monitoring and Maintenance

### Health Monitoring
```bash
# Manual health check
./monitor-suricata.sh

# View container logs
docker-compose logs -f suricata

# Check resource usage
docker stats suricata
```

### Rule Management
```bash
# Update rules manually
./update-rules.sh

# View rule files
ls -la rules/

# Test rule syntax (if suricata binary is available)
suricata -T -c config/suricata.yaml -S rules/suricata.rules
```

### Log Management
Logs are automatically rotated using logrotate:
- **Daily rotation** for all log files
- **7-day retention** with compression
- **Automatic cleanup** of old files

Log locations:
- `logs/eve.json` - Main event log (JSON format)
- `logs/fast.log` - Quick alert summary
- `logs/stats.log` - Performance statistics
- `logs/suricata.log` - Application logs

## Wazuh Integration

### Dashboard Access
Once integrated, Suricata events appear in your Wazuh dashboard:
- Navigate to **Security Events**
- Filter by rule groups: `suricata`, `intrusion_detection`
- View geographic threat maps
- Analyze attack patterns

### Alert Levels
- **Level 12-13**: Critical threats (APT, successful admin access)
- **Level 10-11**: High priority (malware, privilege escalation)
- **Level 7-9**: Medium priority (suspicious domains, anomalies)
- **Level 5-6**: Low priority (normal traffic, blocked content)

### Custom Dashboards
The integration includes pre-configured dashboards for:
- Threat overview and trending
- Network traffic analysis
- DNS security monitoring
- Web application attacks
- Container security events

## Performance Tuning

### Resource Requirements
- **CPU**: 2+ cores recommended for busy networks
- **Memory**: 2GB minimum, 4GB recommended
- **Network**: Promiscuous mode required on monitoring interface
- **Storage**: 10-50GB depending on traffic volume

### Optimization Settings
The configuration is optimized for homelab environments:
- **Multi-threading**: Auto-configured based on CPU cores  
- **Memory management**: Conservative settings to prevent OOM
- **Buffer sizes**: Tuned for typical home network traffic
- **Log rotation**: Prevents disk space issues

## Troubleshooting

### Common Issues

**Container won't start:**
```bash
# Check interface configuration
ip link show enp1s0

# Verify permissions
ls -la /var/run/docker.sock

# Check logs
docker-compose logs suricata
```

**No alerts being generated:**
```bash
# Verify rules are loaded
grep -c "sid:" rules/*.rules

# Check network traffic
tcpdump -i enp1s0 -c 10

# Generate test traffic
curl -H "User-Agent: malicious-scanner" http://httpbin.org/
```

**High CPU usage:**
```bash
# Check stats
grep "packet" logs/stats.log | tail -5

# Review performance logs
cat logs/rule_perf.log

# Adjust threading in suricata.yaml
```

**Wazuh not receiving events:**
```bash
# Check Wazuh manager logs
docker logs wazuh.manager

# Verify log file permissions
ls -la logs/eve.json

# Test log parsing
head -5 logs/eve.json | jq .
```

### Log Analysis

**View specific event types:**
```bash
# DNS queries
grep '"event_type":"dns"' logs/eve.json | jq .

# HTTP requests  
grep '"event_type":"http"' logs/eve.json | jq .

# Alerts only
grep '"event_type":"alert"' logs/eve.json | jq .
```

**Search for specific threats:**
```bash
# SQL injection attempts
grep -i "sql" logs/fast.log

# Malware signatures
grep -i "trojan\|malware\|botnet" logs/fast.log

# Cryptocurrency mining
grep -i "mining\|coin" logs/fast.log
```

## Security Considerations

### Network Placement
- Deploy on a **span/mirror port** for comprehensive monitoring
- Ensure **promiscuous mode** is enabled on monitoring interface
- Consider **network segmentation** for sensitive environments

### Access Control
- **Restrict access** to configuration files (600 permissions)
- **Secure log directories** from unauthorized access
- **Use strong passwords** for web interfaces

### Privacy Protection
- **Anonymize logs** if processing personal data
- **Implement retention policies** for compliance
- **Monitor access patterns** to sensitive information

## Integration with Other Services

### Pi-hole DNS
- Correlates DNS blocks with network threats
- Identifies DNS tunneling attempts
- Monitors malicious domain queries

### Nessus Vulnerability Scanner
- Cross-references CVEs with network attacks
- Validates patch levels against exploits
- Provides vulnerability context for alerts

### Media Services Protection
- Monitors Plex access attempts
- Detects unauthorized streaming
- Protects download automation services

## Automated Maintenance

### Cron Jobs
The deployment automatically sets up:
- **Rule updates**: Daily at 2 AM
- **Health checks**: Every 5 minutes
- **Log rotation**: Daily with compression

### System Integration
- **Systemd services** for reliable monitoring
- **Logrotate configuration** for disk management
- **UFW firewall rules** for secure access

## Advanced Configuration

### Custom Rule Development
Create custom rules in `rules/suricata.rules`:
```
alert tcp $HOME_NET any -> $EXTERNAL_NET any (
    msg:"Custom threat detection"; 
    content:"malicious-string"; 
    classtype:trojan-activity; 
    sid:1000100; 
    rev:1;
)
```

### Performance Profiling
Enable detailed profiling:
```yaml
profiling:
  rules:
    enabled: yes
    filename: rule_perf.log
```

### Machine Learning Integration
Consider integrating with:
- **Elastic Security** for ML-based anomaly detection
- **YARA rules** for malware signature matching
- **Threat intelligence feeds** for IOC correlation

## Contributing

To add new rules or improve the configuration:

1. Test changes in a development environment
2. Validate rule syntax with `suricata -T`
3. Monitor performance impact
4. Document changes in commit messages
5. Follow semantic versioning for releases

## Support and Documentation

### Official Resources
- [Suricata User Guide](https://suricata.readthedocs.io/)
- [Emerging Threats Rules](https://doc.emergingthreats.net/)
- [Wazuh Documentation](https://documentation.wazuh.com/)

### Community Resources
- [Suricata Forum](https://forum.suricata.io/)
- [Security Onion](https://securityonion.net/) - Similar IDS platform
- [r/netsec](https://reddit.com/r/netsec) - Security community

### Local Support
- Check logs in `logs/` directory
- Run health checks with `./monitor-suricata.sh`
- View container status with `docker-compose ps`
- Access Wazuh dashboard for centralized analysis

---

**Deployment Date**: $(date +%Y-%m-%d)  
**Version**: 1.0  
**Maintainer**: scott@homelab.local  
**Last Updated**: $(date '+%Y-%m-%d %H:%M:%S')
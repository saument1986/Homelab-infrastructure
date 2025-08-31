# Security Configuration Documentation

## Overview

This document details the security configurations, monitoring rules, and defensive measures implemented across the homelab infrastructure. The security stack includes Wazuh SIEM for centralized monitoring, Suricata IDS for network intrusion detection, Pi-hole for DNS filtering, Nessus for vulnerability assessment, and Slack for real-time alerting.

## Security Architecture

### Multi-Layer Defense Strategy
- **Network Layer**: Suricata IDS monitors all network traffic for threats
- **DNS Layer**: Pi-hole blocks malicious domains and detects tunneling
- **Host Layer**: Wazuh agents monitor system activity and file integrity
- **Application Layer**: Web attack detection and container security monitoring
- **Alerting Layer**: Slack integration for immediate threat notifications

## Wazuh SIEM Configuration

### Core Security Components

#### Manager Configuration
**File**: `/opt/wazuh-docker/config/wazuh_cluster/wazuh_manager.conf`

```xml
<!-- Vulnerability Detection -->
<vulnerability-detection>
  <enabled>yes</enabled>
  <interval>5m</interval>
  <min_full_scan_interval>6h</min_full_scan_interval>
  <run_on_start>yes</run_on_start>

  <!-- Ubuntu vulnerability provider -->
  <provider name="canonical">
    <enabled>yes</enabled>
    <os>trusty</os>
    <os>xenial</os>
    <os>bionic</os>
    <os>focal</os>
    <os>jammy</os>
    <update_interval>1h</update_interval>
  </provider>

  <!-- Debian vulnerability provider -->
  <provider name="debian">
    <enabled>yes</enabled>
    <os>wheezy</os>
    <os>jessie</os>
    <os>stretch</os>
    <os>buster</os>
    <os>bullseye</os>
    <os>bookworm</os>
    <update_interval>1h</update_interval>
  </provider>

  <!-- RedHat vulnerability provider -->
  <provider name="redhat">
    <enabled>yes</enabled>
    <os>5</os>
    <os>6</os>
    <os>7</os>
    <os>8</os>
    <os>9</os>
    <update_interval>1h</update_interval>
  </provider>

  <!-- Amazon Linux vulnerability provider -->
  <provider name="alas">
    <enabled>yes</enabled>
    <os>amazon-linux</os>
    <os>amazon-linux-2</os>
    <update_interval>1h</update_interval>
  </provider>
</vulnerability-detection>

<!-- Log Monitoring Configuration -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/external/pihole/pihole.log</location>
</localfile>

<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/external/nessus/nessusd.messages</location>
</localfile>
<!-- Suricata IDS Integration -->
<localfile>
  <log_format>json</log_format>
  <location>/var/log/external/suricata/eve.json</location>
</localfile>

<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/external/suricata/fast.log</location>
</localfile>

<!-- Slack Integration -->
<integration>
  <name>slack</name>
  <hook_url>YOUR_WEBHOOK_URL</hook_url>
  <level>7</level>
  <group>authentication_failed,web,attacks,suricata,malware,intrusion_detection</group>
  <api_key>wazuh-slack</api_key>
  <alert_format>json</alert_format>
</integration>
```

## Suricata Network Intrusion Detection System

### Configuration
**File**: `/home/scott/docker/suricata/config/suricata.yaml`

Suricata is configured for comprehensive network monitoring with the following features:

#### Network Capture
- **Interface**: ens18 (auto-detected primary interface)
- **Capture Method**: AF_PACKET with memory mapping for high performance
- **Traffic Processing**: Multi-threaded with CPU affinity optimization

#### Rule Management
- **Emerging Threats**: Automatically updated community rules
- **Custom Rules**: Homelab-specific threat detection rules
- **Rule Categories**: 
  - DNS Security (suspicious TLDs, tunneling detection)
  - Web Application Security (SQL injection, XSS, directory traversal)
  - Command & Control Detection (C2 beacons, suspicious connections)
  - Container Security (breakout attempts, lateral movement)
  - Cryptocurrency Mining Detection
  - Data Exfiltration Patterns

#### Output Configuration
```yaml
outputs:
  - eve-log:
      enabled: yes
      filetype: regular
      filename: eve.json
      types:
        - alert: {metadata: yes, tagged-packets: yes}
        - http: {enabled: yes, extended: yes}
        - dns: {enabled: yes, query: yes, answer: yes}
        - tls: {enabled: yes, extended: yes}
        - ssh: {enabled: yes}
        - files: {enabled: yes}
```

### Custom Security Rules
**File**: `/home/scott/docker/suricata/rules/suricata.rules`

Key homelab-specific rules include:

#### DNS Security Rules
```suricata
# Suspicious TLD monitoring
alert dns $HOME_NET any -> any 53 (msg:"HOMELAB DNS Query to Suspicious TLD"; content:".tk"; nocase; classtype:suspicious-filename-detect; sid:1000001; rev:1;)

# DNS tunneling detection  
alert dns $HOME_NET any -> any 53 (msg:"HOMELAB DNS Tunneling Attempt - Long TXT Query"; dns_query; content:"|00 10 00 01|"; content_len:>100; classtype:trojan-activity; sid:1000003; rev:1;)
```

#### Container Security Rules
```suricata
# Container breakout detection
alert tcp $HOME_NET any -> any any (msg:"HOMELAB Container Breakout Attempt"; flow:established,to_server; content:"docker.sock"; classtype:successful-admin; sid:1000040; rev:1;)

# Kubernetes API access monitoring
alert tcp $HOME_NET any -> any any (msg:"HOMELAB Kubernetes API Access"; flow:established,to_server; content:"/api/v1"; classtype:attempted-admin; sid:1000041; rev:1;)
```

### Integration with Wazuh
**Files**: 
- `/home/scott/docker/suricata/wazuh-integration/suricata_decoders.xml`
- `/home/scott/docker/suricata/wazuh-integration/suricata_rules.xml`

Suricata events are parsed by Wazuh using custom decoders and correlated with specific rules:

#### Alert Correlation Rules
- **Level 12-13**: Critical threats (APT behavior, successful admin access)
- **Level 10-11**: High priority (malware detection, privilege escalation)
- **Level 7-9**: Medium priority (suspicious domains, anomalies)
- **Level 5-6**: Low priority (normal traffic, informational events)

## Slack Real-Time Alerting

### Integration Configuration
**File**: `/home/scott/docker/wazuh-slack-integration/slack-integration.py`

Real-time security notifications are sent to Slack with rich formatting:

#### Alert Severity Levels
```python
SEVERITY_LEVELS = {
    'critical': {'min_level': 12, 'color': '#FF0000', 'emoji': '🚨', 'mention': '@channel'},
    'high': {'min_level': 10, 'color': '#FF8C00', 'emoji': '⚠️', 'mention': '@here'},
    'medium': {'min_level': 7, 'color': '#FFD700', 'emoji': '⚡', 'mention': ''},
    'low': {'min_level': 5, 'color': '#4169E1', 'emoji': 'ℹ️', 'mention': ''}
}
```

#### Alert Categories
- 🌐 Network Security (Suricata alerts)
- 🛡️ Intrusion Detection
- 🦠 Malware Detection
- 🔑 Authentication Events
- 🐳 Container Security
- 🔍 DNS Security
- 📡 Command & Control

### Alert Filtering
**File**: `/home/scott/docker/wazuh-slack-integration/alert-filters.json`

Intelligent filtering prevents alert fatigue:
- **Rate limiting**: Maximum alerts per hour by severity
- **Time-based filtering**: Reduced sensitivity during quiet hours
- **Rule suppression**: Known false positives excluded
- **Source filtering**: Trusted internal IPs have different thresholds

## Pi-hole DNS Security Integration

### Custom Decoders
**File**: `/opt/wazuh-docker/config/wazuh_cluster/custom/decoders/pihole_decoders.xml`

```xml
<decoder name="pihole-dnsmasq">
  <parent>dnsmasq</parent>
  <program_name>^dnsmasq</program_name>
  <regex offset="after_parent">query\[(\w+)\] (\S+) from (\S+)</regex>
  <order>query_type,domain,client_ip</order>
</decoder>

<decoder name="pihole-dnsmasq-reply">
  <parent>dnsmasq</parent>
  <program_name>^dnsmasq</program_name>
  <regex offset="after_parent">reply (\S+) is (\S+)</regex>
  <order>domain,ip_address</order>
</decoder>

<decoder name="pihole-dnsmasq-forward">
  <parent>dnsmasq</parent>
  <program_name>^dnsmasq</program_name>
  <regex offset="after_parent">forwarded (\S+) to (\S+)</regex>
  <order>domain,upstream_dns</order>
</decoder>

<decoder name="pihole-dnsmasq-blocked">
  <parent>dnsmasq</parent>
  <program_name>^dnsmasq</program_name>
  <regex offset="after_parent">gravity blocked (\S+) is ([\d\.]+)</regex>
  <order>blocked_domain,blocked_ip</order>
</decoder>
```

### Security Rules
**File**: `/opt/wazuh-docker/config/wazuh_cluster/custom/rules/pihole_rules.xml`

#### DNS Threat Detection Rules

```xml
<!-- High-priority DNS security events -->
<rule id="150100" level="5">
  <decoded_as>pihole-dnsmasq</decoded_as>
  <description>Pi-hole DNS query detected</description>
  <group>dns,pihole</group>
</rule>

<rule id="150101" level="7">
  <if_sid>150100</if_sid>
  <regex>\.tk$|\.ml$|\.ga$|\.cf$</regex>
  <description>DNS query to suspicious TLD domain: $(domain)</description>
  <group>dns,pihole,suspicious_domain</group>
</rule>

<rule id="150102" level="8">
  <if_sid>150100</if_sid>
  <regex>malware|phishing|botnet|trojan|ransomware</regex>
  <description>DNS query to known malicious domain: $(domain)</description>
  <group>dns,pihole,malware</group>
</rule>

<!-- DNS tunneling detection -->
<rule id="150110" level="9">
  <if_sid>150100</if_sid>
  <field name="query_type">TXT</field>
  <description>Potential DNS tunneling detected - TXT query to: $(domain)</description>
  <group>dns,pihole,tunneling</group>
</rule>

<!-- High frequency queries (potential DDoS) -->
<rule id="150120" level="6" frequency="50" timeframe="300">
  <if_sid>150100</if_sid>
  <same_field>client_ip</same_field>
  <description>High frequency DNS queries from $(client_ip) - Potential DDoS</description>
  <group>dns,pihole,ddos</group>
</rule>

<!-- Blocked domain attempts -->
<rule id="150130" level="6">
  <decoded_as>pihole-dnsmasq-blocked</decoded_as>
  <description>Pi-hole blocked domain access: $(blocked_domain)</description>
  <group>dns,pihole,blocked</group>
</rule>

<rule id="150131" level="8" frequency="10" timeframe="300">
  <if_sid>150130</if_sid>
  <same_field>client_ip</same_field>
  <description>Multiple blocked domain attempts from $(client_ip)</description>
  <group>dns,pihole,blocked,persistent</group>
</rule>

<!-- Cryptocurrency mining domains -->
<rule id="150135" level="8">
  <if_sid>150100</if_sid>
  <regex>coinhive|cryptoloot|jsecoin|minero|webminer</regex>
  <description>Cryptocurrency mining domain detected: $(domain)</description>
  <group>dns,pihole,crypto_mining</group>
</rule>

<!-- Command and Control (C2) indicators -->
<rule id="150140" level="10">
  <if_sid>150100</if_sid>
  <regex>dyndns|no-ip|ddns|ngrok|serveo</regex>
  <description>Potential C2 communication domain: $(domain)</description>
  <group>dns,pihole,c2,command_control</group>
</rule>

<!-- Data exfiltration patterns -->
<rule id="150141" level="9">
  <if_sid>150100</if_sid>
  <field name="query_type">AAAA|TXT</field>
  <regex>[\w]{20,}</regex>
  <description>Suspicious long subdomain query - potential data exfiltration: $(domain)</description>
  <group>dns,pihole,exfiltration</group>
</rule>
```

## Nessus Vulnerability Scanning

### Scanner Configuration
**File**: `/home/scott/docker/nessus/docker-compose.yml`

```yaml
version: '3.8'

services:
  nessus:
    container_name: nessus
    image: tenableofficial/nessus:latest
    restart: unless-stopped
    environment:
      - ACTIVATION_CODE=${NESSUS_ACTIVATION_CODE}
      - USERNAME=${NESSUS_USERNAME:-admin}
      - PASSWORD=${NESSUS_PASSWORD}
      - AUTO_UPDATE=${AUTO_UPDATE:-all}
      - LINKING_KEY=${LINKING_KEY}
      - SCANNER_NAME=${SCANNER_NAME:-nessus-scanner}
    ports:
      - "8834:8834"
    volumes:
      - nessus_data:/opt/nessus
      - ./logs:/opt/nessus/var/nessus/logs
    healthcheck:
      test: ["CMD", "curl", "-f", "-k", "https://localhost:8834/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

### Security Scan Policies

#### Network Infrastructure Scanning
- **Internal Network Discovery**: 192.168.1.0/24
- **Port Scanning**: All TCP/UDP ports on critical hosts
- **Service Enumeration**: Version detection for all services
- **Vulnerability Assessment**: CVE-based security checks

#### Container Security Scanning
- **Docker Host Assessment**: Host-level vulnerability checks
- **Container Image Scanning**: Base image vulnerability detection
- **Runtime Security**: Container escape and privilege escalation tests
- **Network Segmentation**: Inter-container communication audits

## Network Security Architecture

### Pi-hole DNS Filtering

#### Blocked Categories
- **Malware Domains**: Known malicious hosts and C2 servers
- **Phishing Sites**: Credential harvesting and social engineering
- **Cryptocurrency Mining**: Browser-based mining scripts
- **Tracking & Analytics**: Privacy-invasive tracking domains
- **Adult Content**: Optional family-friendly filtering
- **Social Media**: Optional productivity filtering

#### Custom Blocklists
- **Threat Intelligence**: IOCs from security feeds
- **Local Blacklist**: Manually identified threats
- **Regex Filtering**: Pattern-based domain blocking
- **Whitelist Exceptions**: Legitimate services requiring access

### Network Segmentation

#### Container Networks
```yaml
networks:
  media_net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
  
  monitoring:
    driver: bridge
    ipam:
      config:
        - subnet: 172.21.0.0/16
```

#### Host Network Services
- **Plex**: Direct host access for DLNA and discovery
- **Pi-hole**: System-level DNS resolution
- **SSH**: Secure administrative access only

## Security Monitoring & Alerting

### Wazuh Alert Categories

#### High Priority (Level 10+)
- **C2 Communication**: Command and control indicators
- **Data Exfiltration**: Unusual outbound data patterns
- **Privilege Escalation**: Unauthorized access attempts
- **Malware Detection**: Known malicious signatures

#### Medium Priority (Level 7-9)
- **Suspicious Domains**: Questionable TLD or patterns
- **Tunnel Detection**: DNS/HTTP tunneling attempts
- **Failed Authentication**: Multiple login failures
- **Configuration Changes**: System modification events

#### Low Priority (Level 5-6)
- **Normal DNS Queries**: Standard resolution requests
- **Blocked Content**: Pi-hole filtering events
- **System Events**: Normal operational activities
- **Update Activities**: Automated maintenance tasks

### Dashboard Configuration

#### Security Overview Dashboard
- **Threat Summary**: Real-time threat counters
- **Geographic Threat Map**: Attack source visualization
- **Top Threats**: Most frequent security events
- **Vulnerability Status**: Patch management overview

#### DNS Security Dashboard
- **Query Volume**: DNS request patterns over time
- **Blocked Domains**: Top blocked categories and domains
- **Client Activity**: Per-device DNS usage patterns
- **Threat Trends**: Malicious domain access attempts

## Incident Response Procedures

### Automated Response Actions

#### High-Severity Threats
1. **Immediate Alerting**: Real-time notifications via dashboard
2. **Traffic Blocking**: Automatic Pi-hole blacklist updates
3. **Container Isolation**: Network segmentation enforcement
4. **Log Preservation**: Enhanced logging for forensic analysis

#### Medium-Severity Events
1. **Monitoring Enhancement**: Increased log verbosity
2. **Pattern Analysis**: Correlation rule activation
3. **Threshold Adjustment**: Dynamic alert sensitivity
4. **Documentation**: Automatic event cataloging

### Manual Response Workflow

#### Threat Investigation
1. **Event Analysis**: Review Wazuh alert details
2. **Log Correlation**: Cross-reference multiple log sources
3. **Network Analysis**: Examine traffic patterns
4. **Vulnerability Assessment**: Run targeted Nessus scans

#### Containment Actions
1. **Network Isolation**: Isolate affected systems
2. **Service Shutdown**: Stop compromised containers
3. **Access Revocation**: Disable user accounts if needed
4. **Backup Verification**: Ensure clean backup availability

## Compliance & Reporting

### Security Baselines

#### CIS Controls Implementation
- **Asset Management**: Complete service inventory
- **Access Control**: Role-based access restrictions
- **Vulnerability Management**: Regular scanning and patching
- **Log Monitoring**: Comprehensive event collection

#### Privacy Protections
- **Data Minimization**: Limited personal data collection
- **Access Logging**: Complete audit trails
- **Retention Policies**: Automated log rotation
- **Anonymization**: IP address sanitization where possible

### Automated Reporting

#### Daily Reports
- **Security Summary**: 24-hour threat overview
- **System Health**: Service availability status
- **Vulnerability Updates**: New CVE notifications
- **Performance Metrics**: System resource utilization

#### Weekly Reports
- **Threat Trends**: Pattern analysis over time
- **Compliance Status**: Security control effectiveness
- **Capacity Planning**: Resource growth projections
- **Configuration Changes**: System modification summaries

## Backup & Recovery

### Security Configuration Backup

#### Wazuh Configuration
- **Manager Config**: Daily backup of manager settings
- **Custom Rules**: Version control for security rules
- **Dashboards**: Visualization configuration export
- **User Settings**: Account and role configurations

#### Pi-hole Configuration
- **Blocklists**: Custom filtering rule backup
- **Network Settings**: DNS configuration preservation
- **Query Logs**: Historical data archival
- **Admin Settings**: Interface configuration backup

### Disaster Recovery

#### Service Restoration Priority
1. **Pi-hole DNS**: Critical network services first
2. **Wazuh Manager**: Security monitoring restoration
3. **Core Infrastructure**: Essential services second
4. **Media Services**: Non-critical services last

#### Recovery Testing
- **Monthly Drills**: Simulated failure scenarios
- **Configuration Validation**: Automated config testing
- **Performance Benchmarks**: Service level verification
- **Documentation Updates**: Procedure refinement

---

**Security Contact**: scott@homelab.local  
**Last Security Review**: August 2025  
**Next Scheduled Review**: November 2025
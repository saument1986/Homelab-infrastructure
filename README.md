# Homelab Infrastructure

## Overview
Proxmox-based homelab featuring containerized services, network security monitoring, and isolated penetration testing environments for hands-on cybersecurity learning.

## Hardware Specifications
- **CPU**: AMD Ryzen 5 7600
- **Motherboard**: Gigabyte B650M K
- **GPU**: MSI RX6800 (with passthrough)  
- **RAM**: 64GB
- **PSU**: 650W

## Architecture
Running on Proxmox hypervisor with multiple VMs:
- **Ubuntu Server** - Docker containers for services
- **Manjaro Linux** - Primary desktop with GPU passthrough
- **Kali Linux** - Penetration testing environment
- **Pop!_OS** - Secondary desktop environment

## Current Services

### Security & Monitoring Stack
- **Wazuh SIEM** (Port 443): Complete security information and event management with Slack integration
- **Suricata IDS** (Host Network): Network intrusion detection and prevention system
- **Pi-hole DNS** (Host Network): Network-wide ad blocking and DNS filtering
- **Nessus Scanner** (Port 8834): Vulnerability assessment and compliance scanning
- **Uptime Kuma** (Port 3001): Service availability monitoring
- **Portainer** (Port 9000): Docker container management interface

### Media Management Stack
- **Plex** (Host Network): Media streaming server
- **Sonarr** (Port 8989): TV series automation
- **Radarr** (Port 7878): Movie automation
- **Lidarr** (Port 8686): Music automation
- **SABnzbd** (Port 8081): Usenet download client
- **Prowlarr** (Port 9696): Indexer management
- **Overseerr** (Port 5055): Media request management
- **Huntarr** (Port 9705): Additional media automation

### System Management
- **Watchtower**: Automated container updates
- **Tautulli** (Port 8181): Plex analytics and monitoring
- **Dozzle** (Port 8082): Container log aggregation
- **Homarr** - Unified dashboard

### AI & Development
- **Ollama** - Local LLM hosting (Dolphin-Llama3:8b)
- **Open WebUI** - Web interface for AI interactions

## Network Architecture

### Network Configuration
- **Management Network**: 192.168.1.0/24
- **Container Networks**: 
  - `media_net`: Bridge network for media services (172.19.0.x)
  - `monitoring`: Bridge network for monitoring stack (172.20.0.x)
  - `ai_stack`: AI services network (172.23.0.x)
  - Host networking for Plex and Pi-hole

## Security Integrations

### Wazuh SIEM Integrations
- **Slack Alerts**: Real-time security notifications with color-coded severity levels
- **Suricata IDS**: Network intrusion detection with custom homelab rules and Emerging Threats signatures
- **Pi-hole DNS**: Monitoring DNS queries, blocks, and tunneling attempts
- **Nessus Scanner**: Vulnerability assessment integration with automated feeds

### Advanced Threat Detection
- **Network Security**: Suricata monitors all network traffic for intrusions, malware, and suspicious patterns
- **DNS Security**: Pi-hole integration detects malicious domains, C2 communications, and data exfiltration
- **Web Attacks**: Detection of SQL injection, XSS, and application-layer attacks
- **Container Security**: Monitoring for container breakouts and lateral movement
- **Authentication**: Failed login tracking and privilege escalation detection

### Real-time Alerting
- **Slack Integration**: Immediate notifications for critical security events
- **Multi-level Alerts**: Critical (12+), High (10+), Medium (7+) with appropriate urgency
- **Rich Formatting**: Detailed threat context with source IPs, affected systems, and remediation guidance
- **Smart Notifications**: @channel for critical threats, @here for high priority

## Directory Structure

```
/home/scott/docker/
├── wazuh-docker/              # Security monitoring (Wazuh SIEM)
│   ├── docker-compose.yml
│   └── config/
│       └── wazuh_cluster/
│           ├── wazuh_manager.conf    # Includes Slack integration
│           └── custom/
│               ├── decoders/         # Pi-hole, Nessus, Suricata decoders
│               └── rules/            # Custom security correlation rules
├── suricata/                  # Network Intrusion Detection System
│   ├── docker-compose.yml
│   ├── config/
│   │   └── suricata.yaml     # Optimized for homelab monitoring
│   ├── rules/                # Custom + Emerging Threats rules
│   │   ├── suricata.rules    # Homelab-specific security rules
│   │   └── emerging-threats.rules
│   ├── logs/                 # EVE JSON logs monitored by Wazuh
│   ├── wazuh-integration/    # Decoders and rules for Wazuh
│   ├── update-rules.sh       # Automated rule updates
│   └── deploy-suricata.sh    # Complete deployment script
├── wazuh-slack-integration/   # Real-time security alerting
│   ├── slack-integration.py  # Python script for rich Slack notifications
│   ├── alert-filters.json    # Alert filtering and formatting rules
│   ├── test-all-levels.sh    # Test different alert severities
│   └── .env                  # Secure webhook configuration
├── mediastack/                # Media automation services
│   └── docker-compose.yml
├── monitoring-stack/          # System monitoring services
│   └── docker-compose.yml
├── plex/                      # Media streaming
│   └── docker-compose.yml
├── pihole/                    # DNS filtering
│   ├── docker-compose.yml
│   ├── etc-pihole/
│   ├── etc-dnsmasq.d/
│   └── logs/                  # Monitored by Wazuh
├── nessus/                    # Vulnerability scanning
│   ├── docker-compose.yml
│   └── logs/                  # Monitored by Wazuh
└── docs/                      # Detailed documentation
    ├── ARCHITECTURE.md        # Network topology and diagrams
    ├── SECURITY.md           # Security configurations and rules
    └── DEPLOYMENT.md         # Deployment and maintenance guides
```

## Current Projects
- [x] Implement Wazuh SIEM for network monitoring *(Completed)*
- [x] Integrate Pi-hole with security monitoring *(Completed)*
- [x] Deploy Nessus vulnerability scanner *(Completed)*
- [x] Deploy Suricata network intrusion detection *(Completed)*
- [x] Configure Slack alerting for security events *(Completed)*
- [x] Create custom homelab security rules and decoders *(Completed)*
- [ ] Set up vulnerable VMs for penetration testing
- [ ] Add centralized logging with ELK stack
- [ ] Document attack/defense scenarios
- [ ] Implement network segmentation with VLANs

## Learning Goals
- Network security monitoring and threat detection
- Purple team operations (attack and defense)
- Container security best practices
- Infrastructure automation and monitoring
- Security incident response procedures

## Service URLs
- **Wazuh Dashboard**: https://192.168.1.100:443
- **Pi-hole Admin**: http://192.168.1.100/admin
- **Nessus**: https://192.168.1.100:8834
- **Portainer**: http://192.168.1.100:9000
- **Plex**: http://192.168.1.100:32400
- **Overseerr**: http://192.168.1.100:5055

## Documentation
For detailed information, see:
- **[Architecture](docs/ARCHITECTURE.md)** - Network topology and data flows
- **[Security](docs/SECURITY.md)** - Security configurations and monitoring rules
- **[Deployment](docs/DEPLOYMENT.md)** - Setup and maintenance procedures

## Future Enhancements
- **Security Onion** - Additional network monitoring capabilities
- **Vulnerable VMs** - Metasploitable, DVWA for testing
- **SOAR Integration** - Security orchestration and automated response
- **Backup automation** - Automated backup strategies
- **Network segmentation** - VLAN implementation
- **Threat hunting** - Proactive threat detection capabilities

---

**Last Updated**: August 2025  
**Infrastructure Version**: Docker Compose v3.8+  
**Security Stack**: Wazuh 4.12.0 + Suricata IDS + Pi-hole DNS + Nessus Scanner with Slack integration
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
- **Wazuh SIEM** (Port 443): Complete security information and event management
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

### Wazuh-Pi-hole Integration
- **Log Monitoring**: Pi-hole DNS queries and blocks monitored by Wazuh
- **Custom Decoders**: Parse Pi-hole dnsmasq logs for security analysis
- **Alert Rules**: Detect suspicious domains, DNS tunneling, and high-frequency queries
- **Real-time Analysis**: Immediate correlation of DNS security events

### Wazuh-Nessus Integration
- **Vulnerability Feeds**: Automated vulnerability detection for multiple OS platforms
- **Log Integration**: Nessus scan results processed through Wazuh SIEM
- **Compliance Monitoring**: Continuous security posture assessment
- **Threat Intelligence**: Combined vulnerability and behavior analysis

## Directory Structure

```
/home/scott/docker/
├── wazuh-docker/              # Security monitoring (Wazuh SIEM)
│   ├── docker-compose.yml
│   └── config/
│       └── wazuh_cluster/
│           ├── wazuh_manager.conf
│           └── custom/
│               ├── decoders/
│               └── rules/
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
- [ ] Set up vulnerable VMs for penetration testing
- [ ] Add centralized logging with ELK stack
- [ ] Configure Pushover alerting across all services
- [ ] Document attack/defense scenarios

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
- **Advanced alerting** - Integration with Pushover/Discord
- **Backup automation** - Automated backup strategies
- **Network segmentation** - VLAN implementation

---

**Last Updated**: August 2025  
**Infrastructure Version**: Docker Compose v3.8+  
**Security Stack**: Wazuh 4.12.0 with integrated Pi-hole and Nessus monitoring
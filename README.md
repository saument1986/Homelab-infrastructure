# Scott's Homelab Infrastructure

Complete containerized homelab environment running security monitoring, media management, network services, and vulnerability assessment capabilities.

## Architecture Overview

### Network Configuration
- **Management Network**: 192.168.1.0/24
- **Container Networks**: 
  - `media_net`: Bridge network for media services
  - `monitoring`: Bridge network for monitoring stack
  - Host networking for Plex and Pi-hole

### Core Services

#### Security & Monitoring Stack
- **Wazuh SIEM** (Port 443): Complete security information and event management
- **Pi-hole DNS** (Host Network): Network-wide ad blocking and DNS filtering
- **Nessus Scanner** (Port 8834): Vulnerability assessment and compliance scanning
- **Uptime Kuma** (Port 3001): Service availability monitoring
- **Portainer** (Port 9000): Docker container management interface

#### Media Management Stack
- **Plex** (Host Network): Media streaming server
- **Sonarr** (Port 8989): TV series automation
- **Radarr** (Port 7878): Movie automation
- **Lidarr** (Port 8686): Music automation
- **SABnzbd** (Port 8081): Usenet download client
- **Prowlarr** (Port 9696): Indexer management
- **Overseerr** (Port 5055): Media request management
- **Huntarr** (Port 9705): Additional media automation

#### System Management
- **Watchtower**: Automated container updates
- **Tautulli** (Port 8181): Plex analytics and monitoring
- **Dozzle** (Port 8082): Container log aggregation

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
└── README.md                  # This documentation
```

## Service Dependencies

### Critical Path Services
1. **Pi-hole**: Must start first (DNS resolution for all services)
2. **Wazuh**: Core security monitoring platform
3. **Media Stack**: Dependent on network and storage availability
4. **Monitoring Stack**: Watches all other services

### Inter-service Communication
- Pi-hole provides DNS resolution for all containers
- Wazuh monitors logs from Pi-hole and Nessus
- Portainer manages all Docker environments
- Uptime Kuma monitors service availability

## Storage Configuration

### Media Storage
- **TV Shows**: `/mnt/media/TV`
- **Movies**: `/mnt/media/Movies` 
- **Music**: `/mnt/media/Music`
- **Downloads**: `/mnt/media/downloads/`
  - `completed/`: Finished downloads
  - `intermediate/`: Processing directory

### Configuration Storage
- All service configurations stored in respective `/home/scott/docker/[service]/config/` directories
- Persistent volumes for database and application data
- Log aggregation in service-specific log directories

## Security Configurations

### Wazuh SIEM Rules
- **Pi-hole Security Rules** (150100-150141): DNS-based threat detection
- **Vulnerability Detection**: Multi-OS vulnerability scanning enabled
- **Custom Decoders**: Parse Pi-hole dnsmasq and Nessus logs
- **Real-time Correlation**: Combine network and vulnerability intelligence

### Network Security
- **DNS Filtering**: Pi-hole blocks malicious domains at network level
- **Container Isolation**: Separate networks for different service stacks
- **Host Monitoring**: Wazuh agent monitoring host system
- **Log Aggregation**: Centralized security event processing

### Access Control
- **Web Interfaces**: Password-protected dashboards for all services
- **Network Isolation**: Services isolated by Docker networks where possible
- **SSL/TLS**: Secure connections for management interfaces

## Deployment Instructions

### Initial Setup
1. **Clone Repository**: `git clone [repository-url] /home/scott/docker`
2. **Create Directories**: Ensure all mount point directories exist
3. **Set Permissions**: Configure proper ownership for service directories
4. **Environment Variables**: Configure activation codes and passwords

### Service Startup Order
1. **Core Infrastructure**: 
   ```bash
   cd /home/scott/docker/pihole && docker-compose up -d
   ```
2. **Security Stack**:
   ```bash
   cd /opt/wazuh-docker && docker-compose up -d
   cd /home/scott/docker/nessus && docker-compose up -d
   ```
3. **Media Stack**:
   ```bash
   cd /home/scott/docker/mediastack && docker-compose up -d
   cd /home/scott/docker/plex && docker-compose up -d
   ```
4. **Monitoring Stack**:
   ```bash
   cd /home/scott/docker/monitoring-stack && docker-compose up -d
   ```

### Configuration Requirements
- **Nessus Activation**: Configure `NESSUS_ACTIVATION_CODE` environment variable
- **Timezone Configuration**: Set to appropriate timezone (America/New_York)
- **User IDs**: PUID=1000, PGID=1000 for proper file permissions
- **Network Access**: Ensure firewall allows required ports

## Maintenance & Updates

### Automated Updates
- **Watchtower**: Automatically updates containers at 4 AM daily
- **Cleanup**: Removes old container images automatically
- **Health Checks**: Built-in health monitoring for critical services

### Manual Maintenance
- **Log Rotation**: Monitor log file sizes in service directories
- **Security Updates**: Regular review of Wazuh alerts and Nessus scans
- **Capacity Planning**: Monitor disk usage for media and log storage
- **Backup Strategy**: Regular backup of configuration directories

### Monitoring & Alerting
- **Uptime Kuma**: Service availability alerts
- **Wazuh Dashboard**: Security event monitoring
- **Dozzle**: Real-time container log viewing
- **Tautulli**: Plex usage analytics

## Troubleshooting

### Common Issues
- **Container Startup Failures**: Check Docker daemon status and image integrity
- **Network Connectivity**: Verify Pi-hole DNS resolution
- **Storage Issues**: Check mount point permissions and disk space
- **Security Alerts**: Review Wazuh dashboard for threat analysis

### Log Locations
- **Wazuh Logs**: `/var/ossec/logs/` (in container)
- **Pi-hole Logs**: `/home/scott/docker/pihole/logs/`
- **Nessus Logs**: `/home/scott/docker/nessus/logs/`
- **Container Logs**: `docker logs [container-name]`

### Service URLs
- **Wazuh Dashboard**: https://192.168.1.100:443
- **Pi-hole Admin**: http://192.168.1.100/admin
- **Nessus**: https://192.168.1.100:8834
- **Portainer**: http://192.168.1.100:9000
- **Plex**: http://192.168.1.100:32400
- **Overseerr**: http://192.168.1.100:5055

---

**Last Updated**: August 2025  
**Infrastructure Version**: Docker Compose v3.8+  
**Security Stack**: Wazuh 4.12.0 with integrated Pi-hole and Nessus monitoring
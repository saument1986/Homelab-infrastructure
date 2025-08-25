# Homelab Deployment Guide

## Prerequisites

### System Requirements

#### Hardware Specifications
- **CPU**: Minimum 4 cores, 8+ recommended for security stack
- **RAM**: 16GB minimum (8GB for Wazuh, 8GB for services)
- **Storage**: 500GB+ SSD for containers, separate HDD for media
- **Network**: Gigabit Ethernet connection

#### Software Dependencies
- **Docker Engine**: Version 20.10+
- **Docker Compose**: Version 2.0+
- **Git**: For repository management
- **curl/wget**: For service health checks

### Network Configuration
```bash
# Ensure firewall allows required ports
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 53/udp      # Pi-hole DNS
sudo ufw allow 80/tcp      # Pi-hole Web
sudo ufw allow 443/tcp     # Wazuh Dashboard
sudo ufw allow 8834/tcp    # Nessus Scanner
sudo ufw allow 32400/tcp   # Plex Media Server
```

## Initial Deployment

### 1. Repository Setup

```bash
# Clone the homelab configuration
cd /home/scott/
git clone <your-repo-url> docker
cd docker

# Set proper permissions
sudo chown -R 1000:1000 /home/scott/docker
```

### 2. Storage Preparation

```bash
# Create media storage structure
sudo mkdir -p /mnt/media/{TV,Movies,Music,downloads/{completed,intermediate}}
sudo chown -R 1000:1000 /mnt/media

# Create service configuration directories
for service in pihole sonarr radarr lidarr prowlarr overseerr huntarr tautulli nessus; do
    mkdir -p /home/scott/docker/$service/config
done

# Set proper ownership
sudo chown -R 1000:1000 /home/scott/docker
```

### 3. Environment Configuration

```bash
# Create Nessus environment file
cat > /home/scott/docker/nessus/.env << EOF
NESSUS_ACTIVATION_CODE=YOUR_ACTIVATION_CODE_HERE
NESSUS_USERNAME=admin
NESSUS_PASSWORD=YourSecurePassword123
AUTO_UPDATE=all
SCANNER_NAME=homelab-scanner
EOF

# Secure the environment file
chmod 600 /home/scott/docker/nessus/.env
```

### 4. Wazuh SIEM Setup

```bash
# Download and configure Wazuh
cd /opt/
sudo git clone https://github.com/wazuh/wazuh-docker.git
cd wazuh-docker

# Generate certificates for secure communication
sudo docker-compose -f generate-indexer-certs.yml run --rm generator

# Update memory configuration for indexer
sudo sed -i 's/-Xms512m/-Xms1g/g' docker-compose.yml
sudo sed -i 's/-Xmx512m/-Xmx1g/g' docker-compose.yml
```

## Service Deployment Order

### Phase 1: Core Infrastructure

#### Pi-hole DNS (Critical - Deploy First)
```bash
cd /home/scott/docker/pihole

# Start Pi-hole for network DNS
docker-compose up -d

# Wait for initialization
sleep 30

# Verify DNS resolution
nslookup google.com 192.168.1.100
```

#### Wazuh Security Stack
```bash
cd /opt/wazuh-docker

# Deploy Wazuh components
docker-compose up -d

# Wait for indexer initialization
sleep 120

# Verify dashboard access
curl -k -I https://192.168.1.100:443
```

### Phase 2: Security Services

#### Nessus Vulnerability Scanner
```bash
cd /home/scott/docker/nessus

# Deploy Nessus scanner
docker-compose up -d

# Monitor initialization (takes 10-15 minutes)
docker logs -f nessus

# Wait for "All plugins loaded" message
# Access web interface at https://192.168.1.100:8834
```

### Phase 3: Media Stack

#### Media Management Services
```bash
cd /home/scott/docker/mediastack

# Deploy all media services
docker-compose up -d

# Verify services are healthy
docker-compose ps
```

#### Plex Media Server
```bash
cd /home/scott/docker/plex

# Deploy Plex with host networking
docker-compose up -d

# Wait for Plex initialization
sleep 60

# Check Plex availability
curl -I http://192.168.1.100:32400/web
```

### Phase 4: Monitoring Stack

#### System Monitoring
```bash
cd /home/scott/docker/monitoring-stack

# Deploy monitoring services
docker-compose up -d

# Verify all containers are running
docker-compose ps
```

## Post-Deployment Configuration

### Wazuh SIEM Setup

#### 1. Dashboard Access
```bash
# Default credentials (change immediately)
# User: admin
# Password: admin

# Access dashboard
https://192.168.1.100:443
```

#### 2. Agent Installation (Host Monitoring)
```bash
# Download and install Wazuh agent
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo apt-key add -
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list

sudo apt update
sudo apt install wazuh-agent

# Configure agent
sudo sed -i 's/MANAGER_IP/192.168.1.100/g' /var/ossec/etc/ossec.conf

# Start agent
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
```

#### 3. Custom Rules Deployment
```bash
# Copy custom decoders and rules
sudo cp -r /home/scott/docker/wazuh-config/custom/* /opt/wazuh-docker/config/wazuh_cluster/custom/

# Restart Wazuh manager to load custom rules
cd /opt/wazuh-docker
docker-compose restart wazuh.manager
```

### Pi-hole Configuration

#### 1. Initial Setup
```bash
# Access Pi-hole admin interface
http://192.168.1.100/admin

# Default password: Rainbow Sunshine 123
# Change password immediately in Settings > Password
```

#### 2. DNS Configuration
```bash
# Configure upstream DNS servers
# Primary: 1.1.1.1 (Cloudflare)
# Secondary: 8.8.8.8 (Google)

# Enable conditional forwarding for local network
# Local Network: 192.168.1.0/24
# Router IP: 192.168.1.1
```

#### 3. Blocklist Setup
```bash
# Add recommended blocklists
# StevenBlack: https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
# Malware Domain List: https://www.malwaredomainlist.com/hostslist/hosts.txt
# Phishing Army: https://phishing.army/download/phishing_army_blocklist_extended.txt
```

### Nessus Scanner Configuration

#### 1. Initial Setup
```bash
# Access Nessus web interface
https://192.168.1.100:8834

# Use activation code from environment file
# Create admin user with secure password
# Wait for plugin compilation (30-60 minutes)
```

#### 2. Scan Policy Creation
```bash
# Create scan policies for:
# 1. Internal Network Discovery
# 2. Vulnerability Assessment
# 3. Compliance Auditing
# 4. Web Application Testing
```

### Media Services Configuration

#### 1. Sonarr/Radarr/Lidarr Setup
```bash
# Access each service web interface
# Sonarr: http://192.168.1.100:8989
# Radarr: http://192.168.1.100:7878
# Lidarr: http://192.168.1.100:8686

# Configure indexers via Prowlarr
# Set download client to SABnzbd
# Configure media folders
```

#### 2. Plex Configuration
```bash
# Access Plex web interface
http://192.168.1.100:32400/web

# Complete initial setup wizard
# Add media libraries:
# - Movies: /media/Movies
# - TV Shows: /media/TV
# - Music: /media/Music
```

## Service Integration

### Wazuh-Pi-hole Integration

#### 1. Log Mounting
```yaml
# Add to Wazuh docker-compose.yml
volumes:
  - /home/scott/docker/pihole/logs:/var/log/external/pihole:ro
```

#### 2. Custom Decoder Installation
```bash
# Ensure decoders are properly installed
sudo ls -la /opt/wazuh-docker/config/wazuh_cluster/custom/decoders/
sudo ls -la /opt/wazuh-docker/config/wazuh_cluster/custom/rules/
```

### Wazuh-Nessus Integration

#### 1. Vulnerability Detection Configuration
```xml
<!-- Verify in wazuh_manager.conf -->
<vulnerability-detection>
  <enabled>yes</enabled>
  <interval>5m</interval>
  <!-- ... provider configurations ... -->
</vulnerability-detection>
```

#### 2. Log Integration
```yaml
# Nessus log mounting in Wazuh
volumes:
  - /home/scott/docker/nessus/logs:/var/log/external/nessus:ro
```

## Health Checks & Verification

### Service Status Verification

```bash
#!/bin/bash
# Service health check script

services=(
    "pihole:192.168.1.100:80"
    "wazuh:192.168.1.100:443"
    "nessus:192.168.1.100:8834"
    "plex:192.168.1.100:32400"
    "sonarr:192.168.1.100:8989"
    "radarr:192.168.1.100:7878"
    "lidarr:192.168.1.100:8686"
    "portainer:192.168.1.100:9000"
)

echo "Checking service availability..."
for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    host=$(echo $service | cut -d: -f2)
    port=$(echo $service | cut -d: -f3)
    
    if curl -s --max-time 5 http://$host:$port >/dev/null 2>&1; then
        echo "✓ $name is responding"
    else
        echo "✗ $name is not responding"
    fi
done
```

### Container Health Monitoring

```bash
# Check all containers are running
docker ps --filter "status=running" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check for any failed containers
docker ps --filter "status=exited" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Monitor resource usage
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
```

## Backup Procedures

### Configuration Backup

```bash
#!/bin/bash
# Daily configuration backup script

BACKUP_DIR="/home/scott/backups/$(date +%Y-%m-%d)"
mkdir -p "$BACKUP_DIR"

# Backup service configurations
cp -r /home/scott/docker/ "$BACKUP_DIR/docker-configs"

# Backup Wazuh configuration
cp -r /opt/wazuh-docker/config/ "$BACKUP_DIR/wazuh-config"

# Backup Pi-hole configuration
docker exec pihole pihole -a -t > "$BACKUP_DIR/pihole-teleporter.tar.gz"

# Create compressed archive
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"

echo "Backup completed: $BACKUP_DIR.tar.gz"
```

### Media Backup Strategy

```bash
# Media is typically too large for regular backup
# Instead, maintain redundancy through:
# 1. RAID configuration for critical media
# 2. Cloud storage for family photos/videos
# 3. Off-site backup for irreplaceable content
# 4. Automated re-downloading for replaceable content
```

## Troubleshooting

### Common Issues

#### Container Startup Problems
```bash
# Check Docker daemon status
sudo systemctl status docker

# View container logs
docker logs <container-name>

# Restart problematic service
cd /path/to/service
docker-compose restart <service-name>
```

#### Network Connectivity Issues
```bash
# Test DNS resolution
nslookup google.com 192.168.1.100

# Check Docker networks
docker network ls
docker network inspect <network-name>

# Verify port bindings
netstat -tlnp | grep <port>
```

#### Performance Issues
```bash
# Monitor system resources
htop
iotop
df -h

# Check Docker resource usage
docker stats

# Review log sizes
du -sh /var/lib/docker/containers/*/
du -sh /home/scott/docker/*/logs/
```

### Recovery Procedures

#### Service Recovery
```bash
# Stop all services
cd /home/scott/docker
find . -name "docker-compose.yml" -execdir docker-compose down \;

# Start in dependency order
cd pihole && docker-compose up -d && sleep 30
cd ../nessus && docker-compose up -d && sleep 30
cd /opt/wazuh-docker && docker-compose up -d && sleep 120
cd /home/scott/docker/mediastack && docker-compose up -d
cd ../plex && docker-compose up -d
cd ../monitoring-stack && docker-compose up -d
```

#### Data Recovery
```bash
# Restore from backup
BACKUP_FILE="/path/to/backup.tar.gz"
cd /tmp
tar -xzf "$BACKUP_FILE"

# Stop services before restoring
# Restore configurations
# Restart services
```

## Security Hardening

### Post-Deployment Security

```bash
# Change default passwords
# - Pi-hole admin password
# - Wazuh admin password
# - Service API keys

# Enable firewall
sudo ufw enable

# Disable unused services
sudo systemctl disable apache2
sudo systemctl disable bluetooth

# Set up log rotation
sudo logrotate -d /etc/logrotate.conf

# Configure fail2ban
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

### Regular Maintenance

```bash
# Weekly maintenance script
#!/bin/bash

# Update containers
docker system prune -f
cd /home/scott/docker/monitoring-stack
docker-compose pull watchtower

# Clean up logs
find /home/scott/docker/*/logs/ -name "*.log" -mtime +30 -delete

# Backup configurations
/home/scott/scripts/backup.sh

# Generate security report
echo "Security maintenance completed: $(date)"
```

---

**Deployment Status**: Production Ready  
**Last Updated**: August 2025  
**Deployment Time**: ~2-3 hours (excluding Nessus plugin compilation)  
**Support Contact**: scott@homelab.local
# Raspberry Pi Security Monitoring Setup

## Overview
This document provides setup instructions for deploying Pi-hole DNS filtering and Suricata IDS on a Raspberry Pi 5 for network-wide security monitoring.

## Hardware Requirements
- Raspberry Pi 5 (4GB RAM minimum)
- MicroSD card (32GB minimum, Class 10)
- Ethernet connection to network
- Power supply (5V/3A USB-C)

## Base System Setup

### 1. Install Raspberry Pi OS
```bash
# Flash Raspberry Pi OS Lite to SD card
# Enable SSH during setup for headless operation
```

### 2. Initial Configuration
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y git curl wget htop iotop python3 python3-pip

# Configure static IP (recommended)
sudo nano /etc/dhcpcd.conf
# Add:
# interface eth0
# static ip_address=192.168.0.231/24
# static routers=192.168.0.1
# static domain_name_servers=1.1.1.1 8.8.8.8
```

## Pi-hole Installation

### 1. Automated Installation
```bash
# Run Pi-hole installer
curl -sSL https://install.pi-hole.net | bash

# Follow interactive setup:
# - Choose eth0 interface
# - Set static IP: 192.168.0.231
# - Upstream DNS: 1.1.1.1, 8.8.8.8
# - Install web admin interface
# - Install lighttpd web server
```

### 2. Post-Installation Configuration
```bash
# Set admin password
pihole -a -p

# Add custom blocklists (optional)
pihole -w example.com  # Whitelist domain
pihole -b ads.example.com  # Blacklist domain

# Update gravity database
pihole -g
```

### 3. Router Configuration
Configure your router to use the Pi-hole as the primary DNS server:
- Router DNS: 192.168.0.231
- Secondary DNS: 1.1.1.1 (fallback)

## Suricata IDS Installation

### 1. Install Suricata
```bash
# Add Suricata repository
sudo add-apt-repository ppa:oisf/suricata-stable
sudo apt update

# Install Suricata
sudo apt install -y suricata

# Verify installation
suricata --version
```

### 2. Basic Configuration
```bash
# Edit main configuration
sudo nano /etc/suricata/suricata.yaml

# Key settings to modify:
# HOME_NET: "[192.168.0.0/16]"
# EXTERNAL_NET: "!$HOME_NET"
# interface: eth0
# Enable eve-log output
```

### 3. Network Interface Configuration
```bash
# Configure for AF_PACKET mode
sudo nano /etc/suricata/suricata.yaml

# Find af-packet section and configure:
af-packet:
  - interface: eth0
    cluster-id: 99
    cluster-type: cluster_flow
    use-mmap: yes
```

### 4. Update Rules
```bash
# Update Suricata rules
sudo suricata-update

# Enable automatic updates
sudo crontab -e
# Add: 0 2 * * * /usr/bin/suricata-update && /bin/systemctl reload suricata
```

### 5. Noise Reduction Configuration
```bash
# Create threshold configuration
sudo nano /etc/suricata/threshold.config

# Add rules to suppress noisy alerts:
suppress gen_id 1, sig_id 2016149    # STUN Binding Request
suppress gen_id 1, sig_id 2016150    # STUN Binding Response
suppress gen_id 1, sig_id 2027695    # Cloudflare DoH
suppress gen_id 1, sig_id 2210029    # TCP stream invalid ack
suppress gen_id 1, sig_id 2210045    # TCP packet invalid ack

# Reference in main config:
# threshold-file: /etc/suricata/threshold.config
```

## Log Shipping to Wazuh

### 1. Create Log Shipper Script
```bash
# Create log shipper directory
mkdir -p /home/pi/log_shipper
cd /home/pi/log_shipper

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install requests urllib3
```

### 2. Log Shipper Configuration
Create `/home/pi/log_shipper/config.py`:
```python
# Wazuh SIEM Configuration
WAZUH_HOST = "192.168.0.229"
WAZUH_PORT = 9200
WAZUH_USER = "admin"
WAZUH_PASS = "[CONFIGURED_IN_ENVIRONMENT]"
WAZUH_INDEX = "raspberry-pi-logs"

# Log Sources
LOG_FILES = {
    "suricata": {
        "path": "/var/log/suricata/eve.json",
        "type": "json",
        "service": "ids",
        "logtype": "suricata"
    },
    "pihole": {
        "path": "/var/log/pihole/pihole.log", 
        "type": "text",
        "service": "dns",
        "logtype": "pihole"
    }
}

# Only ship critical/high/medium severity alerts (severity < 3)
SEVERITY_FILTER = 3
```

### 3. Systemd Service Setup
```bash
# Create systemd service
sudo nano /etc/systemd/system/log-shipper.service

[Unit]
Description=Security Log Shipper
After=network.target
Wants=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/log_shipper
ExecStart=/home/pi/log_shipper/venv/bin/python log_shipper.py
Restart=always
RestartSec=10
Environment=WAZUH_PASS=your_password_here

[Install]
WantedBy=multi-user.target

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable log-shipper
sudo systemctl start log-shipper
```

## Service Management

### Start/Stop Services
```bash
# Pi-hole
sudo systemctl start pihole-FTL
sudo systemctl stop pihole-FTL
sudo systemctl status pihole-FTL

# Suricata
sudo systemctl start suricata
sudo systemctl stop suricata
sudo systemctl status suricata

# Log shipper
sudo systemctl start log-shipper
sudo systemctl status log-shipper
```

### View Logs
```bash
# Pi-hole logs
tail -f /var/log/pihole/pihole.log
tail -f /var/log/pihole/FTL.log

# Suricata logs
tail -f /var/log/suricata/suricata.log
tail -f /var/log/suricata/eve.json

# Log shipper
journalctl -u log-shipper -f
```

## Monitoring and Maintenance

### Performance Monitoring
```bash
# System resources
htop
iotop

# Suricata performance
sudo suricatasc -c stats

# Pi-hole statistics
pihole -c
```

### Regular Maintenance
```bash
# Update Pi-hole
pihole -up

# Update gravity database
pihole -g

# Update Suricata rules
sudo suricata-update && sudo systemctl reload suricata

# System updates
sudo apt update && sudo apt upgrade -y
```

### Log Rotation
```bash
# Configure logrotate for custom logs
sudo nano /etc/logrotate.d/security-logs

/var/log/suricata/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    postrotate
        /bin/systemctl reload suricata
    endscript
}
```

## Security Considerations

### Network Positioning
- Deploy Pi between router and internal network for optimal traffic visibility
- Configure router to route traffic through Pi-hole for DNS filtering
- Ensure Suricata can see all network traffic (mirror port or inline deployment)

### Access Control
```bash
# Secure SSH access
sudo nano /etc/ssh/sshd_config
# PasswordAuthentication no
# PermitRootLogin no
# AllowUsers pi

# Configure firewall
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80/tcp    # Pi-hole web interface
sudo ufw allow 53/tcp    # DNS
sudo ufw allow 53/udp    # DNS
```

### Backup Configuration
```bash
# Backup Pi-hole configuration
pihole -a -t

# Backup Suricata configuration
sudo tar -czf suricata-backup.tar.gz /etc/suricata/

# Backup log shipper configuration
tar -czf log-shipper-backup.tar.gz /home/pi/log_shipper/
```

## Troubleshooting

### Common Issues
1. **High CPU usage**: Adjust Suricata thread configuration
2. **DNS resolution issues**: Check Pi-hole logs and upstream DNS
3. **Log shipping failures**: Verify Wazuh connectivity and credentials
4. **Storage space**: Implement proper log rotation

### Diagnostic Commands
```bash
# Check service status
sudo systemctl status pihole-FTL suricata log-shipper

# Test DNS resolution
nslookup google.com 192.168.0.231

# Test Suricata rules
sudo suricata -T -c /etc/suricata/suricata.yaml

# Check network connectivity
ping 192.168.0.229  # Wazuh server
```

This setup provides enterprise-grade network security monitoring on a cost-effective Raspberry Pi platform, with intelligent log filtering and centralized SIEM integration.
# Docker Log Management - Quick Start Guide

## Emergency Response (Immediate Action Needed)

If you're experiencing disk space issues due to large log files:

```bash
# 1. Check current disk usage
df -h

# 2. Find largest log files immediately
find /path/to/docker -name "*.log" -size +100M -exec ls -lh {} \;

# 3. Emergency log truncation (keeps last 50MB of each large log)
find /path/to/docker -name "*.log" -size +1G -exec sh -c 'tail -c 50M "$1" > "$1.tmp" && mv "$1.tmp" "$1"' _ {} \;

# 4. Clean up Docker system
docker system prune -f --volumes
```

## 5-Minute Setup

### 1. Install Docker Daemon Limits
```bash
# Create Docker daemon config
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "5"
  }
}
EOF

# Restart Docker
sudo systemctl restart docker
```

### 2. Add Logging to Docker Compose Files
Add to each service in your `docker-compose.yml`:

```yaml
services:
  your-service:
    image: your-image
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"
```

### 3. Quick Monitoring Script
```bash
# Create monitoring script
cat > ~/docker-monitor.sh << 'EOF'
#!/bin/bash
USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$USAGE" -ge 90 ]; then
    echo "ALERT: Disk usage is ${USAGE}%"
    find ~/docker -name "*.log" -size +100M -exec ls -lh {} \;
fi
EOF

chmod +x ~/docker-monitor.sh

# Add to cron (runs every 15 minutes)
(crontab -l 2>/dev/null; echo "*/15 * * * * ~/docker-monitor.sh") | crontab -
```

## 30-Minute Complete Setup

Use the comprehensive templates and documentation provided:

1. **Main Documentation**: `DOCKER_LOG_MANAGEMENT.md`
2. **Monitoring Scripts**: `templates/monitoring-scripts.sh`
3. **Logrotate Configs**: `templates/logrotate-configs.conf`
4. **Compose Templates**: `templates/docker-compose-logging.yml`

### Installation Steps:
```bash
# 1. Copy templates to your docker directory
cp templates/* ~/docker/templates/

# 2. Customize monitoring script
nano ~/docker/templates/monitoring-scripts.sh
# Update DOCKER_ROOT and other paths

# 3. Set up logrotate
sudo cp templates/logrotate-configs.conf /etc/logrotate.d/docker-logs
# Edit file paths in the config

# 4. Install monitoring
cp templates/monitoring-scripts.sh ~/docker-monitor.sh
chmod +x ~/docker-monitor.sh

# 5. Set up cron jobs
crontab -e
# Add these lines:
# */15 * * * * ~/docker-monitor.sh monitor
# 0 2 * * * ~/docker-monitor.sh cleanup
```

## Common Service Configurations

### Security Monitoring (Suricata, etc.)
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "25m"
    max-file: "3"
```

### Media Servers (Plex, etc.)
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "25m"
    max-file: "3"
```

### Standard Services (*arr apps, etc.)
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "2"
```

## Troubleshooting

### Log Rotation Not Working
```bash
# Test logrotate config
sudo logrotate -d /etc/logrotate.d/docker-logs

# Force rotation
sudo logrotate -f /etc/logrotate.d/docker-logs
```

### Docker Daemon Config Not Applied
```bash
# Check Docker info
docker info | grep -A 10 "Logging Driver"

# Restart Docker
sudo systemctl restart docker
```

### Monitoring Script Issues
```bash
# Test script manually
~/docker-monitor.sh monitor

# Check cron logs
grep CRON /var/log/syslog
```

## Maintenance Commands

```bash
# Weekly: Check disk usage trends
df -h && du -sh ~/docker/*/

# Monthly: Review and clean old logs
find ~/docker -name "*.log.*.gz" -mtime +60 -delete

# Quarterly: Update log rotation policies
sudo nano /etc/logrotate.d/docker-logs
```

## Key Metrics to Monitor

- **Disk Usage**: Alert at 80%, critical at 90%
- **Log File Sizes**: Alert at 100MB, critical at 500MB
- **Docker System Usage**: Monitor via `docker system df`
- **Service Health**: Check container status regularly

## Files Overview

- `DOCKER_LOG_MANAGEMENT.md` - Complete documentation
- `templates/monitoring-scripts.sh` - Customizable monitoring
- `templates/logrotate-configs.conf` - Log rotation templates
- `templates/docker-compose-logging.yml` - Compose file examples
- `QUICK_START.md` - This guide

## Support

If you need help:
1. Check the main documentation in `DOCKER_LOG_MANAGEMENT.md`
2. Review template files for configuration examples
3. Test configurations in a non-production environment first
4. Monitor system for 24-48 hours after implementation
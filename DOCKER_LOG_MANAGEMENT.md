# Docker Log Management and Disk Space Prevention

## Problem Statement

Docker containers can generate excessive log files that consume significant disk space if not properly managed. This is particularly problematic for security monitoring tools, media servers, and network analysis applications that generate verbose logs by default.

### Common Symptoms
- Rapid disk space consumption
- Large log files (>100MB) accumulating without rotation
- System performance degradation due to disk I/O
- Risk of service interruption when disk space is exhausted

## Solution Overview

Implement a comprehensive log management system with the following components:
1. **Docker daemon logging limits**
2. **Application-specific log rotation**  
3. **Automated disk space monitoring**
4. **Scheduled cleanup processes**
5. **Optimized application logging configurations**

## Implementation

### 1. Docker Daemon Configuration

Create `/etc/docker/daemon.json` to set global logging limits:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "5"
  },
  "storage-driver": "overlay2"
}
```

Apply changes:
```bash
sudo systemctl restart docker
```

### 2. Docker Compose Logging Configuration

Add logging configuration to all services in `docker-compose.yml`:

```yaml
services:
  your-service:
    image: your-image
    # Standard logging configuration
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"
    
  high-volume-service:
    image: your-image
    # For services with verbose logging
    logging:
      driver: "json-file"
      options:
        max-size: "25m"
        max-file: "3"
```

### 3. System-wide Log Rotation

Create logrotate configurations in `/etc/logrotate.d/`:

**General Docker logs** (`/etc/logrotate.d/docker-logs`):
```bash
/path/to/docker/*/logs/*.log {
    size 50M
    missingok
    rotate 5
    compress
    delaycompress
    notifempty
    create 644 user user
}
```

**High-volume application logs** (`/etc/logrotate.d/app-specific`):
```bash
/path/to/app/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 user user
    postrotate
        docker kill --signal=HUP container_name 2>/dev/null || true
    endscript
}
```

### 4. Disk Space Monitoring Script

Create `/home/user/disk-monitor.sh`:

```bash
#!/bin/bash
ALERT_THRESHOLD=90
LOG_FILE="/home/user/disk-monitor.log"

check_disk_usage() {
    local usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ "$usage" -ge "$ALERT_THRESHOLD" ]; then
        echo "[$timestamp] ALERT: Disk usage is ${usage}%" >> "$LOG_FILE"
        logger -t disk-monitor "DISK SPACE ALERT: ${usage}% usage"
        
        # Log largest directories and files
        echo "[$timestamp] Top directories:" >> "$LOG_FILE"
        du -sh /path/to/docker/*/ 2>/dev/null | sort -hr | head -10 >> "$LOG_FILE"
    else
        echo "[$timestamp] Disk usage OK: ${usage}%" >> "$LOG_FILE"
    fi
    
    # Check for large log files
    find /path/to/docker -name "*.log" -size +100M -exec ls -lh {} \; 2>/dev/null | while read line; do
        local file=$(echo "$line" | awk '{print $9}')
        local size=$(echo "$line" | awk '{print $5}')
        echo "[$timestamp] Large log file: $file ($size)" >> "$LOG_FILE"
    done
}

check_disk_usage
```

### 5. Automated Cleanup Script

Create `/home/user/docker-cleanup.sh`:

```bash
#!/bin/bash
LOG_FILE="/home/user/docker-cleanup.log"

cleanup_docker_system() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Starting Docker cleanup..." >> "$LOG_FILE"
    
    # Remove unused containers, networks, images
    docker system prune -f --volumes >> "$LOG_FILE" 2>&1
    
    # Clean old rotated logs (>30 days)
    find /path/to/docker -name "*.log.*.gz" -mtime +30 -delete 2>/dev/null
    
    # Truncate extremely large current logs (>1GB) to last 100MB
    find /path/to/docker -name "*.log" -size +1G -exec sh -c '
        for file; do
            echo "Truncating large log: $file"
            tail -c 100M "$file" > "$file.tmp" && mv "$file.tmp" "$file"
        done
    ' sh {} +
    
    echo "[$timestamp] Cleanup completed" >> "$LOG_FILE"
}

cleanup_docker_system
```

### 6. Cron Job Configuration

Set up automated execution:

```bash
# Disk monitoring every 15 minutes
*/15 * * * * /home/user/disk-monitor.sh

# Daily cleanup at 2 AM
0 2 * * * /home/user/docker-cleanup.sh

# Force log rotation at 3 AM
0 3 * * * /usr/sbin/logrotate -f /etc/logrotate.d/docker-logs
```

## Application-Specific Optimizations

### Security Monitoring Tools
For network monitoring and security analysis applications:

```yaml
# In application configuration file
logging:
  default-log-level: warning  # Reduce from 'info' or 'debug'
  outputs:
    - console:
        enabled: no  # Disable console logging
    - file:
        enabled: yes
        level: warning
        filename: app.log
        
# Disable verbose profiling and debugging features
profiling:
  enabled: no
debug-mode: false
```

### Media Servers
Reduce transcoding and metadata logging verbosity:

```yaml
logging:
  level: WARN
  console: false
  file:
    enabled: true
    max-size: 25MB
    max-files: 3
```

## Monitoring and Alerting

### Key Metrics to Monitor
- Disk usage percentage
- Log file sizes
- Docker system space usage
- Container restart frequency due to disk space

### Alert Thresholds
- **Warning**: 80% disk usage
- **Critical**: 90% disk usage  
- **Log file size**: >100MB for individual files

### Dashboard Integration
Consider integrating with monitoring solutions:
- Prometheus + Grafana for metrics
- ELK Stack for log analysis
- Simple email/Slack notifications via cron

## Testing and Validation

### Test Log Rotation
```bash
# Test configuration without rotating
sudo logrotate -d /etc/logrotate.d/docker-logs

# Force rotation for testing
sudo logrotate -f /etc/logrotate.d/docker-logs
```

### Verify Docker Logging Limits
```bash
# Check current container log sizes
docker ps --format "table {{.Names}}\t{{.Image}}" | while read name image; do
    if [ "$name" != "NAMES" ]; then
        echo "$name: $(docker logs --tail 1 $name 2>&1 | wc -c) bytes"
    fi
done

# Monitor Docker system usage
docker system df
```

### Validate Monitoring
```bash
# Test monitoring script
./disk-monitor.sh

# Check monitoring log
tail -f /home/user/disk-monitor.log

# Test cleanup script
./docker-cleanup.sh
```

## Troubleshooting

### Common Issues

**1. Log rotation not working**
- Check file permissions on log directories
- Verify logrotate configuration syntax: `logrotate -d /path/to/config`
- Ensure applications can recreate log files after rotation

**2. Docker daemon config not applied**
- Restart Docker service: `sudo systemctl restart docker`
- Check Docker daemon logs: `sudo journalctl -u docker.service`
- Verify JSON syntax in `/etc/docker/daemon.json`

**3. Cron jobs not executing**
- Check cron service: `sudo systemctl status cron`
- Verify crontab syntax: `crontab -l`
- Check script permissions and paths

**4. Scripts failing**
- Review script logs in designated log files
- Test scripts manually with full paths
- Check system logger: `journalctl -f`

## Best Practices

1. **Test in non-production first** - Validate all configurations
2. **Monitor initial deployment** - Watch for 24-48 hours after implementation
3. **Regular maintenance** - Review and adjust thresholds periodically
4. **Backup important logs** - Archive critical logs before cleanup
5. **Document customizations** - Keep track of application-specific settings

## Benefits

- **Prevents disk exhaustion** - Proactive space management
- **Improves system performance** - Reduces I/O overhead
- **Reduces maintenance overhead** - Automated cleanup processes
- **Enables better monitoring** - Centralized log management
- **Scalable solution** - Works across multiple Docker services

## Maintenance Schedule

- **Daily**: Automated cleanup and rotation
- **Weekly**: Review disk usage trends and large file reports
- **Monthly**: Adjust rotation policies and cleanup thresholds
- **Quarterly**: Review and update application logging configurations

This comprehensive approach ensures sustainable log management while maintaining security monitoring capabilities and system performance.
# Docker Log Management Documentation

## Overview
This directory contains comprehensive documentation and templates for implementing Docker log management and disk space prevention in homelab environments.

## Problem Solved
Prevents Docker containers from consuming excessive disk space due to uncontrolled log growth, specifically addressing issues where log files can grow to hundreds of GB without proper rotation.

## Documentation Structure

### Primary Documentation
- **[DOCKER_LOG_MANAGEMENT.md](DOCKER_LOG_MANAGEMENT.md)** - Complete implementation guide
- **[QUICK_START.md](QUICK_START.md)** - 5-minute emergency response and setup guide

### Templates Directory
- **[docker-compose-logging.yml](templates/docker-compose-logging.yml)** - Logging configurations for different service types
- **[logrotate-configs.conf](templates/logrotate-configs.conf)** - System-wide log rotation templates
- **[monitoring-scripts.sh](templates/monitoring-scripts.sh)** - Customizable monitoring and alerting scripts

## Quick Implementation

### Emergency Response (Disk Full)
```bash
# Find and truncate large logs immediately
find ~/docker -name "*.log" -size +1G -exec sh -c 'tail -c 50M "$1" > "$1.tmp" && mv "$1.tmp" "$1"' _ {} \;
docker system prune -f --volumes
```

### Basic Setup (5 minutes)
1. Configure Docker daemon logging limits
2. Add logging sections to docker-compose.yml files
3. Set up basic monitoring script with cron

### Complete Setup (30 minutes)
1. Install comprehensive logrotate configurations
2. Deploy customizable monitoring scripts
3. Set up automated cleanup processes
4. Configure application-specific optimizations

## Key Features

### Docker Daemon Configuration
- Global logging limits (50MB max size, 5 files)
- JSON file driver with automatic rotation
- Configurable per-service overrides

### Log Rotation
- Size-based and time-based rotation policies
- Compression to save space
- Service-specific configurations
- Automatic cleanup of old logs

### Monitoring & Alerting
- Real-time disk usage monitoring
- Large file detection and alerts
- Docker system health checks
- Customizable alert thresholds

### Automated Cleanup
- Scheduled removal of old logs
- Docker system pruning
- Temporary file cleanup
- Emergency log truncation

## Service-Specific Configurations

### High-Volume Services
Media servers, reverse proxies, download clients:
- 25MB max log size
- 3 file retention
- Daily rotation

### Security/Monitoring Services
Network monitors, SIEM components:
- 100MB max log size for detailed logs
- 5 file retention
- Signal-based log reopening

### Standard Services
Web applications, APIs, databases:
- 50MB max log size
- 5 file retention
- Standard rotation

### Low-Volume Services
Utilities, schedulers, lightweight services:
- 10MB max log size
- 2 file retention
- Minimal overhead

## Installation Methods

### Method 1: Template-Based Setup
1. Copy templates to your environment
2. Customize paths and thresholds
3. Install configurations system-wide
4. Set up cron jobs

### Method 2: Script-Based Installation
1. Use provided installation scripts
2. Run automated configuration
3. Verify setup with test commands

### Method 3: Manual Configuration
1. Follow step-by-step documentation
2. Implement each component individually
3. Test and validate each step

## Monitoring Dashboard Metrics

Track these key indicators:
- **Disk Usage**: Overall and Docker-specific
- **Log File Sizes**: Per service and total
- **Docker System Usage**: Images, containers, volumes
- **Service Health**: Container status and restarts

## Maintenance Schedule

### Daily (Automated)
- Log rotation execution
- Cleanup of old files
- Disk usage monitoring

### Weekly (Manual)
- Review monitoring logs
- Check for unusual growth patterns
- Validate service health

### Monthly (Manual)
- Update rotation policies
- Review and adjust thresholds
- Archive important logs

### Quarterly (Manual)
- Update application configurations
- Review and optimize policies
- Plan capacity upgrades

## Testing & Validation

### Pre-Production Testing
```bash
# Test logrotate configurations
sudo logrotate -d /etc/logrotate.d/docker-logs

# Validate Docker logging
docker info | grep -A 10 "Logging Driver"

# Test monitoring scripts
./monitoring-scripts.sh monitor
```

### Production Monitoring
```bash
# Monitor initial deployment
tail -f /var/log/monitoring.log

# Check disk usage trends
df -h && docker system df

# Validate log rotation
ls -la ~/docker/*/logs/
```

## Troubleshooting Guide

### Common Issues
1. **Log rotation not working** - Check permissions and syntax
2. **Docker config not applied** - Restart Docker daemon
3. **Monitoring alerts not working** - Verify cron jobs and scripts
4. **Services not respecting limits** - Check compose file syntax

### Debug Commands
```bash
# Check Docker daemon config
docker info

# Test logrotate
sudo logrotate -d /path/to/config

# Monitor cron execution
grep CRON /var/log/syslog

# Check file permissions
ls -la /var/log/ /etc/logrotate.d/
```

## Security Considerations

- **Log file permissions**: Restrict access to sensitive logs
- **Cleanup policies**: Balance retention with compliance needs  
- **Monitoring alerts**: Avoid exposing sensitive paths in alerts
- **Backup strategy**: Archive important logs before cleanup

## Performance Impact

### Minimal Overhead
- Log rotation runs during low-usage hours
- Compression reduces I/O impact
- Monitoring scripts are lightweight
- Cleanup processes are optimized

### Resource Usage
- CPU: <1% during rotation and cleanup
- Memory: <50MB for monitoring processes
- Disk I/O: Minimal impact with proper scheduling
- Network: None (local operations only)

## Benefits

1. **Prevents disk exhaustion** - Proactive space management
2. **Improves system performance** - Reduces log file I/O overhead
3. **Reduces maintenance burden** - Automated cleanup and rotation
4. **Enables better monitoring** - Centralized log management
5. **Scales with infrastructure** - Works across multiple services
6. **Cost effective** - No additional software licensing

## Contributing

When adding new service configurations:
1. Follow existing template patterns
2. Test thoroughly in non-production
3. Document service-specific requirements
4. Update relevant template files
5. Add troubleshooting notes

## Support

For implementation assistance:
1. Review main documentation first
2. Check template examples for similar services
3. Test configurations in isolated environment
4. Monitor system for 48 hours after deployment

---

**Last Updated**: September 2025
**Version**: 1.0
**Compatibility**: Docker 20.x+, Ubuntu 20.04+, Most Linux distributions
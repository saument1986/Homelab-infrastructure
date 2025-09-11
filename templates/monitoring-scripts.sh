#!/bin/bash
# Docker Log Monitoring and Alerting Script Templates
# Customizable monitoring solutions for Docker homelab environments

# ===== CONFIGURATION SECTION =====
# Customize these variables for your environment

# Disk usage alert thresholds (percentage)
WARNING_THRESHOLD=80
CRITICAL_THRESHOLD=90

# File size thresholds for log files (in MB)
LARGE_FILE_THRESHOLD=100
HUGE_FILE_THRESHOLD=500

# Paths (customize for your setup)
DOCKER_ROOT="/path/to/docker"
LOG_DIR="/path/to/logs"
MONITOR_LOG="${LOG_DIR}/disk-monitor.log"
CLEANUP_LOG="${LOG_DIR}/cleanup.log"

# Email settings (optional)
ENABLE_EMAIL_ALERTS=false
EMAIL_RECIPIENT="admin@yourdomain.com"
EMAIL_SUBJECT_PREFIX="[Homelab Alert]"

# Slack webhook (optional)
ENABLE_SLACK_ALERTS=false
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"

# ===== UTILITY FUNCTIONS =====

log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1"
}

send_alert() {
    local severity="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to file
    echo "[$timestamp] $severity: $message" >> "$MONITOR_LOG"
    
    # Log to system journal
    logger -t docker-monitor "$severity: $message"
    
    # Email alert (if enabled)
    if [ "$ENABLE_EMAIL_ALERTS" = true ]; then
        echo "$message" | mail -s "$EMAIL_SUBJECT_PREFIX $severity" "$EMAIL_RECIPIENT"
    fi
    
    # Slack alert (if enabled)
    if [ "$ENABLE_SLACK_ALERTS" = true ]; then
        local color="warning"
        [ "$severity" = "CRITICAL" ] && color="danger"
        
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$EMAIL_SUBJECT_PREFIX $severity: $message\",\"color\":\"$color\"}" \
            "$SLACK_WEBHOOK_URL" 2>/dev/null
    fi
}

# ===== MONITORING FUNCTIONS =====

check_disk_usage() {
    local usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ "$usage" -ge "$CRITICAL_THRESHOLD" ]; then
        send_alert "CRITICAL" "Disk usage is ${usage}% (threshold: ${CRITICAL_THRESHOLD}%)"
        
        # Additional details for critical alerts
        log_message "Top 10 largest directories in Docker:"
        du -sh "$DOCKER_ROOT"/*/ 2>/dev/null | sort -hr | head -10 >> "$MONITOR_LOG"
        
        # Show Docker system usage
        log_message "Docker system usage:"
        docker system df >> "$MONITOR_LOG" 2>/dev/null || echo "Docker not available" >> "$MONITOR_LOG"
        
        return 1
    elif [ "$usage" -ge "$WARNING_THRESHOLD" ]; then
        send_alert "WARNING" "Disk usage is ${usage}% (warning threshold: ${WARNING_THRESHOLD}%)"
        return 1
    else
        log_message "Disk usage OK: ${usage}%"
        return 0
    fi
}

check_large_log_files() {
    local found_large_files=false
    
    # Check for huge files (>500MB)
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            local size_mb=$(du -m "$file" 2>/dev/null | cut -f1)
            if [ "$size_mb" -ge "$HUGE_FILE_THRESHOLD" ]; then
                send_alert "CRITICAL" "Huge log file detected: $file (${size_mb}MB)"
                found_large_files=true
            fi
        fi
    done < <(find "$DOCKER_ROOT" -name "*.log" -size +${HUGE_FILE_THRESHOLD}M -print0 2>/dev/null)
    
    # Check for large files (>100MB)
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            local size_mb=$(du -m "$file" 2>/dev/null | cut -f1)
            if [ "$size_mb" -ge "$LARGE_FILE_THRESHOLD" ] && [ "$size_mb" -lt "$HUGE_FILE_THRESHOLD" ]; then
                send_alert "WARNING" "Large log file detected: $file (${size_mb}MB)"
                found_large_files=true
            fi
        fi
    done < <(find "$DOCKER_ROOT" -name "*.log" -size +${LARGE_FILE_THRESHOLD}M -size -${HUGE_FILE_THRESHOLD}M -print0 2>/dev/null)
    
    if [ "$found_large_files" = false ]; then
        log_message "No large log files detected"
    fi
}

check_docker_health() {
    if ! command -v docker &> /dev/null; then
        send_alert "WARNING" "Docker command not available"
        return 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        send_alert "CRITICAL" "Docker daemon is not responding"
        return 1
    fi
    
    # Check for containers in unhealthy state
    local unhealthy_containers=$(docker ps --filter health=unhealthy --format '{{.Names}}' 2>/dev/null)
    if [ -n "$unhealthy_containers" ]; then
        send_alert "WARNING" "Unhealthy containers detected: $unhealthy_containers"
    fi
    
    # Check Docker system usage
    local docker_usage=$(docker system df --format "{{.Type}}\t{{.TotalCount}}\t{{.Size}}" 2>/dev/null)
    if [ -n "$docker_usage" ]; then
        log_message "Docker system status:"
        echo "$docker_usage" >> "$MONITOR_LOG"
    fi
    
    return 0
}

generate_usage_report() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    log_message "=== System Usage Report ==="
    
    # Disk usage summary
    log_message "Disk usage by partition:"
    df -h >> "$MONITOR_LOG"
    
    # Top directories by size
    log_message "Top 10 largest directories in Docker root:"
    du -sh "$DOCKER_ROOT"/*/ 2>/dev/null | sort -hr | head -10 >> "$MONITOR_LOG"
    
    # Log file statistics
    log_message "Log file statistics:"
    local total_logs=$(find "$DOCKER_ROOT" -name "*.log" -type f 2>/dev/null | wc -l)
    local total_log_size=$(find "$DOCKER_ROOT" -name "*.log" -type f -exec du -ch {} + 2>/dev/null | tail -1 | cut -f1)
    echo "Total log files: $total_logs" >> "$MONITOR_LOG"
    echo "Total log size: $total_log_size" >> "$MONITOR_LOG"
    
    # Docker system info
    if command -v docker &> /dev/null; then
        log_message "Docker system information:"
        docker system df >> "$MONITOR_LOG" 2>/dev/null
        
        log_message "Running containers:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Size}}" >> "$MONITOR_LOG" 2>/dev/null
    fi
}

# ===== CLEANUP FUNCTIONS =====

cleanup_old_logs() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Starting log cleanup..." >> "$CLEANUP_LOG"
    
    # Clean up compressed rotated logs older than 30 days
    local cleaned_compressed=$(find "$DOCKER_ROOT" -name "*.log.*.gz" -mtime +30 -delete -print 2>/dev/null | wc -l)
    echo "[$timestamp] Removed $cleaned_compressed old compressed log files" >> "$CLEANUP_LOG"
    
    # Clean up temporary files
    local cleaned_temp=$(find "$DOCKER_ROOT" -name "*.tmp" -o -name "*.temp" -mtime +1 -delete -print 2>/dev/null | wc -l)
    echo "[$timestamp] Removed $cleaned_temp temporary files" >> "$CLEANUP_LOG"
    
    # Clean up core dumps older than 7 days
    local cleaned_cores=$(find "$DOCKER_ROOT" -name "core.*" -mtime +7 -delete -print 2>/dev/null | wc -l)
    echo "[$timestamp] Removed $cleaned_cores core dump files" >> "$CLEANUP_LOG"
}

cleanup_docker_system() {
    if ! command -v docker &> /dev/null; then
        echo "Docker not available for cleanup" >> "$CLEANUP_LOG"
        return 1
    fi
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Starting Docker system cleanup..." >> "$CLEANUP_LOG"
    
    # Clean up stopped containers
    docker container prune -f >> "$CLEANUP_LOG" 2>&1
    
    # Clean up unused networks
    docker network prune -f >> "$CLEANUP_LOG" 2>&1
    
    # Clean up unused images (be careful with this)
    docker image prune -f >> "$CLEANUP_LOG" 2>&1
    
    # Clean up build cache
    docker builder prune -f >> "$CLEANUP_LOG" 2>&1
    
    # Clean up unused volumes (CAUTION: only if you're sure)
    # Uncomment the next line only if you understand the risks
    # docker volume prune -f >> "$CLEANUP_LOG" 2>&1
    
    echo "[$timestamp] Docker system cleanup completed" >> "$CLEANUP_LOG"
}

truncate_huge_logs() {
    local size_limit_mb=100
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] Checking for logs larger than 1GB to truncate..." >> "$CLEANUP_LOG"
    
    find "$DOCKER_ROOT" -name "*.log" -size +1G -type f | while read -r logfile; do
        echo "[$timestamp] Truncating huge log file: $logfile" >> "$CLEANUP_LOG"
        
        # Keep last 100MB of the file
        tail -c ${size_limit_mb}M "$logfile" > "$logfile.tmp" && mv "$logfile.tmp" "$logfile"
        
        # Update file permissions
        local owner=$(stat -c '%U:%G' "$logfile" 2>/dev/null || echo "root:root")
        chown "$owner" "$logfile" 2>/dev/null || true
    done
}

# ===== MAIN EXECUTION FUNCTIONS =====

run_monitoring() {
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    log_message "=== Docker Monitoring Check Started ===" >> "$MONITOR_LOG"
    
    # Run all monitoring checks
    check_disk_usage
    local disk_status=$?
    
    check_large_log_files
    check_docker_health
    
    # Generate detailed report if issues found
    if [ $disk_status -ne 0 ]; then
        generate_usage_report
    fi
    
    log_message "=== Docker Monitoring Check Completed ===" >> "$MONITOR_LOG"
}

run_cleanup() {
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] === Docker Cleanup Started ===" >> "$CLEANUP_LOG"
    
    # Show disk usage before cleanup
    echo "[$timestamp] Disk usage before cleanup:" >> "$CLEANUP_LOG"
    df -h / >> "$CLEANUP_LOG"
    
    # Run cleanup tasks
    cleanup_old_logs
    cleanup_docker_system
    truncate_huge_logs
    
    # Show disk usage after cleanup
    echo "[$timestamp] Disk usage after cleanup:" >> "$CLEANUP_LOG"
    df -h / >> "$CLEANUP_LOG"
    
    echo "[$timestamp] === Docker Cleanup Completed ===" >> "$CLEANUP_LOG"
}

# ===== SCRIPT EXECUTION =====

# Check command line arguments
case "${1:-monitor}" in
    "monitor")
        run_monitoring
        ;;
    "cleanup")
        run_cleanup
        ;;
    "both")
        run_monitoring
        run_cleanup
        ;;
    "report")
        mkdir -p "$LOG_DIR"
        generate_usage_report
        ;;
    *)
        echo "Usage: $0 [monitor|cleanup|both|report]"
        echo "  monitor - Run monitoring checks (default)"
        echo "  cleanup - Run cleanup tasks"
        echo "  both    - Run both monitoring and cleanup"
        echo "  report  - Generate detailed usage report"
        exit 1
        ;;
esac

# ===== INSTALLATION NOTES =====
# 
# 1. Customize the configuration section at the top of this script
# 2. Make the script executable: chmod +x monitoring-scripts.sh
# 3. Test the script: ./monitoring-scripts.sh monitor
# 4. Set up cron jobs:
#    */15 * * * * /path/to/monitoring-scripts.sh monitor
#    0 2 * * * /path/to/monitoring-scripts.sh cleanup
#    0 6 * * 1 /path/to/monitoring-scripts.sh report
# 
# 5. For email alerts, install and configure mail:
#    sudo apt install mailutils
#    Configure /etc/postfix/main.cf or use external SMTP
# 
# 6. For Slack alerts, create a webhook in your Slack workspace:
#    Go to https://api.slack.com/messaging/webhooks
#    Create an incoming webhook and update SLACK_WEBHOOK_URL
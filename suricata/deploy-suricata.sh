#!/bin/bash

# Suricata Deployment and Testing Script
# Complete deployment of Suricata IDS with Wazuh integration

set -e

SCRIPT_DIR="/home/scott/docker/suricata"
LOG_FILE="$SCRIPT_DIR/logs/deployment.log"
INTERFACE="enp1s0"  # Update this to match your network interface

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

# Create logs directory
mkdir -p "$SCRIPT_DIR/logs"

log "Starting Suricata deployment..."

# Step 1: Detect network interface
log "Detecting network interface..."
if ! ip link show "$INTERFACE" &>/dev/null; then
    warn "Interface $INTERFACE not found. Detecting available interfaces:"
    ip link show | grep -E "^[0-9]+:" | grep -v lo | head -5
    
    # Try to detect the primary interface
    DETECTED_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [ -n "$DETECTED_INTERFACE" ]; then
        log "Detected primary interface: $DETECTED_INTERFACE"
        INTERFACE="$DETECTED_INTERFACE"
        
        # Update docker-compose.yml with correct interface
        sed -i "s/enp1s0/$INTERFACE/g" "$SCRIPT_DIR/docker-compose.yml"
        sed -i "s/enp1s0/$INTERFACE/g" "$SCRIPT_DIR/config/suricata.yaml"
        log "Updated configuration files with interface: $INTERFACE"
    else
        error "Could not detect network interface. Please update INTERFACE variable in script."
        exit 1
    fi
fi

# Step 2: Check prerequisites
log "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    error "Docker is not installed!"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose is not installed!"
    exit 1
fi

# Check if user can run docker commands
if ! docker ps &> /dev/null; then
    error "Cannot run docker commands. Please add user to docker group or run as root."
    exit 1
fi

# Step 3: Download and update rules
log "Downloading Suricata rules..."
cd "$SCRIPT_DIR"
if ! ./update-rules.sh; then
    error "Failed to download rules!"
    exit 1
fi

# Step 4: Install Wazuh integration
log "Installing Wazuh integration..."
if [ -d "/opt/wazuh-docker" ]; then
    if ! ./wazuh-integration/install-integration.sh; then
        warn "Wazuh integration installation had issues, but continuing..."
    fi
else
    warn "Wazuh not found at /opt/wazuh-docker - skipping integration"
fi

# Step 5: Start Suricata
log "Starting Suricata container..."
if ! docker-compose up -d suricata; then
    error "Failed to start Suricata container!"
    exit 1
fi

# Step 6: Wait for initialization
log "Waiting for Suricata to initialize..."
sleep 30

# Step 7: Verify container is running
log "Verifying Suricata is running..."
if ! docker ps | grep -q suricata; then
    error "Suricata container is not running!"
    docker-compose logs suricata
    exit 1
fi

# Step 8: Check logs are being generated
log "Checking log generation..."
sleep 10

if [ ! -f "$SCRIPT_DIR/logs/eve.json" ]; then
    warn "EVE JSON log not found yet, checking container logs..."
    docker-compose logs --tail=50 suricata
fi

if [ ! -f "$SCRIPT_DIR/logs/fast.log" ]; then
    warn "Fast log not found yet"
fi

# Step 9: Generate test traffic for verification
log "Generating test traffic for verification..."

# Test 1: Basic HTTP request
curl -s http://httpbin.org/get > /dev/null &
sleep 2

# Test 2: DNS queries
nslookup google.com > /dev/null &
nslookup facebook.com > /dev/null &
sleep 2

# Test 3: Test suspicious activity (if rules allow)
curl -s -H "User-Agent: suspicious-scanner" http://httpbin.org/user-agent > /dev/null &
sleep 2

log "Test traffic generated"

# Step 10: Check for alerts
log "Checking for generated alerts..."
sleep 10

if [ -f "$SCRIPT_DIR/logs/eve.json" ]; then
    ALERT_COUNT=$(grep -c '"event_type":"alert"' "$SCRIPT_DIR/logs/eve.json" 2>/dev/null || echo "0")
    log "Found $ALERT_COUNT alerts in EVE log"
    
    if [ "$ALERT_COUNT" -gt 0 ]; then
        log "Recent alerts:"
        grep '"event_type":"alert"' "$SCRIPT_DIR/logs/eve.json" | tail -3 | jq -r '.timestamp + " - " + .alert.signature' 2>/dev/null || \
        grep '"event_type":"alert"' "$SCRIPT_DIR/logs/eve.json" | tail -3
    fi
else
    warn "EVE log file not found"
fi

if [ -f "$SCRIPT_DIR/logs/fast.log" ]; then
    FAST_ALERTS=$(wc -l < "$SCRIPT_DIR/logs/fast.log" 2>/dev/null || echo "0")
    log "Found $FAST_ALERTS entries in fast log"
    
    if [ "$FAST_ALERTS" -gt 0 ]; then
        log "Recent fast log entries:"
        tail -3 "$SCRIPT_DIR/logs/fast.log"
    fi
fi

# Step 11: Performance check
log "Checking Suricata performance..."
if [ -f "$SCRIPT_DIR/logs/stats.log" ]; then
    log "Stats log is being generated"
    if grep -q "packets" "$SCRIPT_DIR/logs/stats.log" 2>/dev/null; then
        PACKETS=$(grep "packets" "$SCRIPT_DIR/logs/stats.log" | tail -1)
        log "Latest packet stats: $PACKETS"
    fi
fi

# Step 12: Container health check
log "Performing container health check..."
CONTAINER_STATUS=$(docker inspect suricata --format='{{.State.Health.Status}}' 2>/dev/null || echo "no-healthcheck")
log "Container health status: $CONTAINER_STATUS"

CPU_USAGE=$(docker stats --no-stream suricata --format "{{.CPUPerc}}" 2>/dev/null || echo "N/A")
MEM_USAGE=$(docker stats --no-stream suricata --format "{{.MemUsage}}" 2>/dev/null || echo "N/A")
log "Resource usage - CPU: $CPU_USAGE, Memory: $MEM_USAGE"

# Step 13: Wazuh integration test
log "Testing Wazuh integration..."
if pgrep -f "wazuh-manager" > /dev/null; then
    log "Wazuh manager is running"
    
    # Check if Wazuh can see Suricata logs
    if [ -f "/opt/wazuh-docker/config/wazuh_cluster/wazuh_manager.conf" ]; then
        if grep -q "suricata" "/opt/wazuh-docker/config/wazuh_cluster/wazuh_manager.conf" 2>/dev/null; then
            log "Wazuh is configured to monitor Suricata logs"
        else
            warn "Wazuh configuration may not include Suricata monitoring"
        fi
    fi
    
    # Restart Wazuh manager to ensure it picks up new logs
    if [ -d "/opt/wazuh-docker" ]; then
        log "Restarting Wazuh manager to ensure log integration..."
        cd /opt/wazuh-docker
        docker-compose restart wazuh.manager
        cd "$SCRIPT_DIR"
    fi
else
    warn "Wazuh manager not running - logs will not be integrated"
fi

# Step 14: Create monitoring cron job
log "Setting up monitoring cron job..."
if ! crontab -l 2>/dev/null | grep -q "monitor-suricata.sh"; then
    (crontab -l 2>/dev/null; echo "*/5 * * * * /home/scott/docker/suricata/monitor-suricata.sh") | crontab -
    log "Added Suricata monitoring cron job (every 5 minutes)"
fi

# Step 15: Final verification
log "Performing final verification..."

# Check all required files exist
REQUIRED_FILES=(
    "$SCRIPT_DIR/logs/eve.json"
    "$SCRIPT_DIR/logs/fast.log"
    "$SCRIPT_DIR/logs/stats.log"
    "$SCRIPT_DIR/config/suricata.yaml"
    "$SCRIPT_DIR/rules/suricata.rules"
    "$SCRIPT_DIR/rules/emerging-threats.rules"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        log "✓ $file exists"
    else
        warn "✗ $file missing"
    fi
done

# Step 16: Display summary
log "Deployment Summary:"
log "=================="
log "• Suricata container: $(docker ps --filter name=suricata --format "{{.Status}}")"
log "• Monitoring interface: $INTERFACE"
log "• Rules loaded: $(ls -1 $SCRIPT_DIR/rules/*.rules | wc -l) rule files"
log "• Log directory: $SCRIPT_DIR/logs/"
log "• Wazuh integration: $([ -d "/opt/wazuh-docker" ] && echo "Configured" || echo "Not available")"

log "Useful commands:"
log "• View live alerts: tail -f $SCRIPT_DIR/logs/fast.log"
log "• View JSON events: tail -f $SCRIPT_DIR/logs/eve.json | jq ."
log "• Container logs: docker-compose -f $SCRIPT_DIR/docker-compose.yml logs -f suricata"
log "• Restart Suricata: docker-compose -f $SCRIPT_DIR/docker-compose.yml restart suricata"
log "• Update rules: $SCRIPT_DIR/update-rules.sh"
log "• Health check: $SCRIPT_DIR/monitor-suricata.sh"

if [ -d "/opt/wazuh-docker" ]; then
    log "• Wazuh dashboard: https://$(hostname -I | awk '{print $1}'):443"
fi

log "Deployment completed successfully!"
log "Monitor the logs for a few minutes to ensure everything is working properly."

# Create a quick status check script
cat > "$SCRIPT_DIR/status.sh" << 'EOF'
#!/bin/bash
echo "=== Suricata Status ==="
echo "Container: $(docker ps --filter name=suricata --format "{{.Names}} - {{.Status}}")"
echo "Alerts today: $(grep $(date +%Y-%m-%d) /home/scott/docker/suricata/logs/fast.log 2>/dev/null | wc -l)"
echo "Log sizes:"
ls -lh /home/scott/docker/suricata/logs/*.log 2>/dev/null | awk '{print "  " $9 ": " $5}'
echo "Latest alert:"
tail -1 /home/scott/docker/suricata/logs/fast.log 2>/dev/null || echo "  No alerts yet"
EOF

chmod +x "$SCRIPT_DIR/status.sh"

log "Quick status script created: $SCRIPT_DIR/status.sh"
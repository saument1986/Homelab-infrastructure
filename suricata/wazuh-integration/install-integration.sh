#!/bin/bash

# Suricata-Wazuh Integration Installation Script
# This script configures Wazuh to monitor Suricata logs

set -e

WAZUH_CONFIG_DIR="/opt/wazuh-docker/config/wazuh_cluster"
SURICATA_DIR="/home/scott/docker/suricata"
LOG_FILE="$SURICATA_DIR/logs/wazuh-integration.log"

echo "$(date): Starting Suricata-Wazuh integration setup..." | tee -a "$LOG_FILE"

# Check if Wazuh is installed
if [ ! -d "$WAZUH_CONFIG_DIR" ]; then
    echo "$(date): Error: Wazuh configuration directory not found at $WAZUH_CONFIG_DIR" | tee -a "$LOG_FILE"
    echo "Please ensure Wazuh is installed and running first." | tee -a "$LOG_FILE"
    exit 1
fi

# Create custom directories if they don't exist
echo "$(date): Creating Wazuh custom configuration directories..." | tee -a "$LOG_FILE"
sudo mkdir -p "$WAZUH_CONFIG_DIR/custom/decoders"
sudo mkdir -p "$WAZUH_CONFIG_DIR/custom/rules"

# Copy decoders and rules
echo "$(date): Installing Suricata decoders and rules..." | tee -a "$LOG_FILE"
sudo cp "$SURICATA_DIR/wazuh-integration/suricata_decoders.xml" "$WAZUH_CONFIG_DIR/custom/decoders/"
sudo cp "$SURICATA_DIR/wazuh-integration/suricata_rules.xml" "$WAZUH_CONFIG_DIR/custom/rules/"

# Set proper ownership
sudo chown -R 1000:1000 "$WAZUH_CONFIG_DIR/custom/"

# Add Suricata log monitoring to Wazuh manager configuration
echo "$(date): Configuring Wazuh to monitor Suricata logs..." | tee -a "$LOG_FILE"

# Create a temporary configuration addition
cat > /tmp/suricata_localfile.conf << 'EOF'

<!-- Suricata EVE JSON Log Monitoring -->
<localfile>
  <log_format>json</log_format>
  <location>/var/log/external/suricata/eve.json</location>
</localfile>

<!-- Suricata Fast Alert Log -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/external/suricata/fast.log</location>
</localfile>

<!-- Suricata Stats Log -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/external/suricata/stats.log</location>
</localfile>
EOF

# Add to Wazuh manager configuration if not already present
if ! sudo grep -q "suricata/eve.json" "$WAZUH_CONFIG_DIR/wazuh_manager.conf" 2>/dev/null; then
    echo "$(date): Adding Suricata log monitoring to Wazuh configuration..." | tee -a "$LOG_FILE"
    sudo sed -i '/<\/ossec_config>/i\
' "$WAZUH_CONFIG_DIR/wazuh_manager.conf"
    
    sudo cat /tmp/suricata_localfile.conf >> "$WAZUH_CONFIG_DIR/wazuh_manager.conf"
    echo "$(date): Suricata log monitoring added to configuration" | tee -a "$LOG_FILE"
else
    echo "$(date): Suricata log monitoring already configured" | tee -a "$LOG_FILE"
fi

# Clean up temporary file
rm -f /tmp/suricata_localfile.conf

# Update docker-compose.yml to mount Suricata logs
echo "$(date): Updating Wazuh docker-compose.yml for Suricata log access..." | tee -a "$LOG_FILE"

WAZUH_COMPOSE_FILE="/opt/wazuh-docker/docker-compose.yml"

if [ -f "$WAZUH_COMPOSE_FILE" ]; then
    # Check if Suricata logs are already mounted
    if ! grep -q "suricata/logs" "$WAZUH_COMPOSE_FILE"; then
        echo "$(date): Adding Suricata log volume mount to Wazuh manager..." | tee -a "$LOG_FILE"
        
        # Create backup
        sudo cp "$WAZUH_COMPOSE_FILE" "$WAZUH_COMPOSE_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Add volume mount for Suricata logs
        sudo sed -i '/wazuh\.manager:/,/volumes:/{
            /volumes:/a\
      - /home/scott/docker/suricata/logs:/var/log/external/suricata:ro
        }' "$WAZUH_COMPOSE_FILE"
        
        echo "$(date): Suricata log volume mount added" | tee -a "$LOG_FILE"
    else
        echo "$(date): Suricata logs already mounted in Wazuh" | tee -a "$LOG_FILE"
    fi
else
    echo "$(date): Warning: Wazuh docker-compose.yml not found at expected location" | tee -a "$LOG_FILE"
fi

# Create Suricata dashboard configuration
echo "$(date): Creating Suricata dashboard configuration..." | tee -a "$LOG_FILE"

cat > "$SURICATA_DIR/wazuh-integration/suricata_dashboard.json" << 'EOF'
{
  "version": "1.0",
  "objects": [
    {
      "id": "suricata-alerts-overview",
      "type": "dashboard",
      "attributes": {
        "title": "Suricata Alerts Overview",
        "description": "Real-time monitoring of Suricata IDS alerts and events",
        "panelsJSON": "[{\"gridData\":{\"x\":0,\"y\":0,\"w\":24,\"h\":15,\"i\":\"1\"},\"panelIndex\":\"1\",\"embeddableConfig\":{},\"panelRefName\":\"panel_1\"}]",
        "timeRestore": false,
        "version": 1
      }
    }
  ]
}
EOF

# Create monitoring script
echo "$(date): Creating Suricata monitoring script..." | tee -a "$LOG_FILE"

cat > "$SURICATA_DIR/monitor-suricata.sh" << 'EOF'
#!/bin/bash

# Suricata Health Monitoring Script
# Monitors Suricata container and log processing

SURICATA_DIR="/home/scott/docker/suricata"
LOG_FILE="$SURICATA_DIR/logs/monitor.log"

echo "$(date): Starting Suricata health check..." | tee -a "$LOG_FILE"

# Check if Suricata container is running
if ! docker ps | grep -q suricata; then
    echo "$(date): ERROR: Suricata container is not running!" | tee -a "$LOG_FILE"
    
    # Attempt to start Suricata
    echo "$(date): Attempting to start Suricata..." | tee -a "$LOG_FILE"
    cd "$SURICATA_DIR"
    docker-compose up -d suricata
    
    if [ $? -eq 0 ]; then
        echo "$(date): Suricata started successfully" | tee -a "$LOG_FILE"
    else
        echo "$(date): Failed to start Suricata" | tee -a "$LOG_FILE"
        exit 1
    fi
else
    echo "$(date): Suricata container is running" | tee -a "$LOG_FILE"
fi

# Check log file sizes
EVE_LOG="$SURICATA_DIR/logs/eve.json"
FAST_LOG="$SURICATA_DIR/logs/fast.log"

if [ -f "$EVE_LOG" ]; then
    EVE_SIZE=$(stat -f%z "$EVE_LOG" 2>/dev/null || stat -c%s "$EVE_LOG" 2>/dev/null)
    echo "$(date): EVE log size: $EVE_SIZE bytes" | tee -a "$LOG_FILE"
else
    echo "$(date): WARNING: EVE log file not found" | tee -a "$LOG_FILE"
fi

if [ -f "$FAST_LOG" ]; then
    FAST_SIZE=$(stat -f%z "$FAST_LOG" 2>/dev/null || stat -c%s "$FAST_LOG" 2>/dev/null)
    echo "$(date): Fast log size: $FAST_SIZE bytes" | tee -a "$LOG_FILE"
else
    echo "$(date): WARNING: Fast log file not found" | tee -a "$LOG_FILE"
fi

# Check for recent alerts
if [ -f "$EVE_LOG" ]; then
    RECENT_ALERTS=$(tail -100 "$EVE_LOG" | grep '"event_type":"alert"' | wc -l)
    echo "$(date): Recent alerts (last 100 lines): $RECENT_ALERTS" | tee -a "$LOG_FILE"
fi

# Check Wazuh integration
if pgrep -f "wazuh-manager" > /dev/null; then
    echo "$(date): Wazuh manager is running - integration active" | tee -a "$LOG_FILE"
else
    echo "$(date): WARNING: Wazuh manager not detected" | tee -a "$LOG_FILE"
fi

echo "$(date): Health check completed" | tee -a "$LOG_FILE"
EOF

chmod +x "$SURICATA_DIR/monitor-suricata.sh"

# Create logrotate configuration
echo "$(date): Creating log rotation configuration..." | tee -a "$LOG_FILE"

sudo tee /etc/logrotate.d/suricata << 'EOF'
/home/scott/docker/suricata/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 644 1000 1000
    postrotate
        /usr/bin/docker kill -s HUP suricata 2>/dev/null || true
    endscript
}
EOF

# Create systemd service for monitoring
echo "$(date): Creating systemd monitoring service..." | tee -a "$LOG_FILE"

sudo tee /etc/systemd/system/suricata-monitor.service << 'EOF'
[Unit]
Description=Suricata Health Monitor
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/home/scott/docker/suricata/monitor-suricata.sh
User=scott
Group=scott

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/suricata-monitor.timer << 'EOF'
[Unit]
Description=Run Suricata Health Monitor every 5 minutes
Requires=suricata-monitor.service

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start the timer
sudo systemctl daemon-reload
sudo systemctl enable suricata-monitor.timer
sudo systemctl start suricata-monitor.timer

echo "$(date): Integration setup completed successfully!" | tee -a "$LOG_FILE"
echo "$(date): Next steps:" | tee -a "$LOG_FILE"
echo "  1. Restart Wazuh manager: cd /opt/wazuh-docker && docker-compose restart wazuh.manager" | tee -a "$LOG_FILE"
echo "  2. Start Suricata: cd /home/scott/docker/suricata && ./update-rules.sh && docker-compose up -d" | tee -a "$LOG_FILE"
echo "  3. Check logs: tail -f /home/scott/docker/suricata/logs/eve.json" | tee -a "$LOG_FILE"
echo "  4. Monitor alerts in Wazuh dashboard" | tee -a "$LOG_FILE"
EOF
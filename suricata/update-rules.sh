#!/bin/bash

# Suricata Rule Update Script
# Downloads and updates Emerging Threats rules

set -e

RULES_DIR="/home/scott/docker/suricata/rules"
CONFIG_DIR="/home/scott/docker/suricata/config"
LOG_FILE="/home/scott/docker/suricata/logs/rule-update.log"

echo "$(date): Starting Suricata rule update..." | tee -a "$LOG_FILE"

# Create rules directory if it doesn't exist
mkdir -p "$RULES_DIR"

# Download Emerging Threats Open rules
echo "$(date): Downloading Emerging Threats Open rules..." | tee -a "$LOG_FILE"
cd "$RULES_DIR"

# Remove old rules
rm -f emerging-threats.rules emerging-threats.rules.tar.gz

# Download latest rules
if curl -s -o emerging-threats.rules.tar.gz "https://rules.emergingthreats.net/open/suricata/emerging.rules.tar.gz"; then
    echo "$(date): Successfully downloaded rules archive" | tee -a "$LOG_FILE"
    
    # Extract rules
    tar -xzf emerging-threats.rules.tar.gz
    
    # Combine all rules into a single file for easier management
    find . -name "*.rules" -not -name "emerging-threats.rules" -exec cat {} \; > emerging-threats.rules
    
    # Clean up extracted files
    rm -rf rules/
    rm -f emerging-threats.rules.tar.gz
    
    echo "$(date): Rules extracted and combined successfully" | tee -a "$LOG_FILE"
else
    echo "$(date): Failed to download rules!" | tee -a "$LOG_FILE"
    exit 1
fi

# Create basic suricata.rules with local rules
cat > "$RULES_DIR/suricata.rules" << 'EOF'
# Local Suricata Rules for Homelab Security
# These rules complement the Emerging Threats ruleset

# DNS Security Rules
alert dns $HOME_NET any -> any 53 (msg:"HOMELAB DNS Query to Suspicious TLD"; content:".tk"; nocase; classtype:suspicious-filename-detect; sid:1000001; rev:1;)
alert dns $HOME_NET any -> any 53 (msg:"HOMELAB DNS Query to Recently Registered Domain"; content:".ml"; nocase; classtype:suspicious-filename-detect; sid:1000002; rev:1;)
alert dns $HOME_NET any -> any 53 (msg:"HOMELAB DNS Tunneling Attempt - Long TXT Query"; dns_query; content:"|00 10 00 01|"; content_len:>100; classtype:trojan-activity; sid:1000003; rev:1;)

# Web Application Security
alert http $HOME_NET any -> any any (msg:"HOMELAB SQL Injection Attempt"; flow:established,to_server; content:"union"; nocase; content:"select"; nocase; classtype:web-application-attack; sid:1000010; rev:1;)
alert http $HOME_NET any -> any any (msg:"HOMELAB XSS Attempt"; flow:established,to_server; content:"<script"; nocase; classtype:web-application-attack; sid:1000011; rev:1;)
alert http $HOME_NET any -> any any (msg:"HOMELAB Directory Traversal Attempt"; flow:established,to_server; content:"../"; classtype:web-application-attack; sid:1000012; rev:1;)

# Command and Control Detection
alert tcp $HOME_NET any -> $EXTERNAL_NET any (msg:"HOMELAB Possible C2 Beacon"; flow:established,to_server; dsize:<100; threshold:type threshold, track by_src, count 10, seconds 300; classtype:trojan-activity; sid:1000020; rev:1;)
alert tcp $HOME_NET any -> $EXTERNAL_NET any (msg:"HOMELAB Suspicious Outbound Connection"; flow:established,to_server; content:"POST"; nocase; content:"base64"; nocase; classtype:trojan-activity; sid:1000021; rev:1;)

# Cryptocurrency Mining Detection
alert tcp $HOME_NET any -> $EXTERNAL_NET any (msg:"HOMELAB Crypto Mining Pool Connection"; flow:established,to_server; content:"stratum"; classtype:coin-mining; sid:1000030; rev:1;)
alert http $HOME_NET any -> any any (msg:"HOMELAB Browser Crypto Mining Script"; flow:established,to_server; content:"coinhive"; nocase; classtype:coin-mining; sid:1000031; rev:1;)

# Container Escape Attempts
alert tcp $HOME_NET any -> any any (msg:"HOMELAB Container Breakout Attempt"; flow:established,to_server; content:"docker.sock"; classtype:successful-admin; sid:1000040; rev:1;)
alert tcp $HOME_NET any -> any any (msg:"HOMELAB Kubernetes API Access"; flow:established,to_server; content:"/api/v1"; classtype:attempted-admin; sid:1000041; rev:1;)

# Lateral Movement Detection
alert tcp $HOME_NET any -> $HOME_NET 22 (msg:"HOMELAB SSH Lateral Movement"; flow:established,to_server; threshold:type threshold, track by_src, count 5, seconds 300; classtype:attempted-admin; sid:1000050; rev:1;)
alert smb $HOME_NET any -> $HOME_NET 445 (msg:"HOMELAB SMB Admin Share Access"; flow:established,to_server; content:"ADMIN$"; classtype:attempted-admin; sid:1000051; rev:1;)

# Data Exfiltration Detection
alert tcp $HOME_NET any -> $EXTERNAL_NET any (msg:"HOMELAB Large Outbound Data Transfer"; flow:established,to_server; dsize:>10000; threshold:type threshold, track by_src, count 10, seconds 60; classtype:sdf; sid:1000060; rev:1;)
alert dns $HOME_NET any -> any 53 (msg:"HOMELAB DNS Exfiltration - Long Subdomain"; dns_query; content_len:>50; classtype:sdf; sid:1000061; rev:1;)

# IoT Device Security
alert tcp $HOME_NET any -> $EXTERNAL_NET any (msg:"HOMELAB IoT Device Unusual Outbound Connection"; flow:established,to_server; content:"User-Agent|3a 20|"; content:"curl"; classtype:trojan-activity; sid:1000070; rev:1;)

# Media Server Protection  
alert http $HOME_NET any -> any 32400 (msg:"HOMELAB Plex Unauthorized Access Attempt"; flow:established,to_server; content:"GET"; content:"/library"; classtype:attempted-user; sid:1000080; rev:1;)
EOF

# Set ownership and permissions
chown 1000:1000 "$RULES_DIR"/*
chmod 644 "$RULES_DIR"/*

# Validate rules syntax if suricata is available
if command -v suricata &> /dev/null; then
    echo "$(date): Validating rule syntax..." | tee -a "$LOG_FILE"
    if suricata -T -c "$CONFIG_DIR/suricata.yaml" -S "$RULES_DIR/suricata.rules" -S "$RULES_DIR/emerging-threats.rules" &>> "$LOG_FILE"; then
        echo "$(date): Rule validation successful" | tee -a "$LOG_FILE"
    else
        echo "$(date): Rule validation failed - check log file" | tee -a "$LOG_FILE"
        exit 1
    fi
fi

# Restart Suricata container if running
if docker ps | grep -q suricata; then
    echo "$(date): Restarting Suricata container to load new rules..." | tee -a "$LOG_FILE"
    cd /home/scott/docker/suricata
    docker-compose restart suricata
    echo "$(date): Suricata container restarted" | tee -a "$LOG_FILE"
fi

echo "$(date): Rule update completed successfully" | tee -a "$LOG_FILE"
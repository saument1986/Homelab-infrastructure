# Homelab Infrastructure

## Overview
Proxmox-based homelab featuring containerized services, network security monitoring, and isolated penetration testing environments for hands-on cybersecurity learning.

## Hardware Specifications
- **CPU**: AMD Ryzen 5 7600
- **Motherboard**: Gigabyte B650M K
- **GPU**: MSI RX6800 (with passthrough)  
- **RAM**: 64GB
- **PSU**: 650W

## Architecture
Running on Proxmox hypervisor with multiple VMs:
- **Ubuntu Server** - Docker containers for services
- **Manjaro Linux** - Primary desktop with GPU passthrough
- **Kali Linux** - Penetration testing environment
- **Pop!_OS** - Secondary desktop environment

## Current Services

### Media Management Stack
- **Plex** - Media server
- **Sonarr** - TV series management
- **Radarr** - Movie management  
- **Lidarr** - Music management
- **Overseerr** - Media request management
- **Prowlarr** - Indexer management
- **Sabnzbd** - Download client
- **Huntarr** - Media hunting automation

### Network & Security
- **Pi-hole** - DNS-level ad blocking and filtering
- **Fail2ban** - Intrusion prevention (planned)

### Monitoring & Management  
- **Uptime Kuma** - Service monitoring and alerting
- **Tautulli** - Plex analytics and monitoring
- **Portainer** - Docker container management
- **Dozzle** - Real-time Docker log viewer
- **Watchtower** - Automated container updates
- **Homarr** - Unified dashboard

### AI & Development
- **Ollama** - Local LLM hosting (Dolphin-Llama3:8b)
- **Open WebUI** - Web interface for AI interactions

## Network Architecture
Services are organized into Docker networks:
- **Media Stack** (172.19.0.x) - Core media services
- **Monitoring Stack** (172.20.0.x) - Monitoring and management
- **AI Stack** (172.23.0.x) - LLM and AI services

## Current Projects
- [ ] Implement Security Onion for network monitoring
- [ ] Set up vulnerable VMs for penetration testing
- [ ] Add centralized logging with ELK stack
- [ ] Configure Pushover alerting across all services
- [ ] Document attack/defense scenarios

## Learning Goals
- Network security monitoring and threat detection
- Purple team operations (attack and defense)
- Container security best practices
- Infrastructure automation and monitoring
- Security incident response procedures

## Future Enhancements
- **Wazuh/Security Onion** - SIEM and network monitoring
- **Vulnerable VMs** - Metasploitable, DVWA for testing
- **Advanced alerting** - Integration with Pushover/Discord
- **Backup automation** - Automated backup strategies
- **Network segmentation** - VLAN implementation

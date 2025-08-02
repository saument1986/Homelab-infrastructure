# Media Server Setup - Plex Docker Integration

## Overview

Successfully deployed Plex in Docker container on Ubuntu Server VM with storage passthrough from Proxmox host.

## Architecture

- **Host**: Proxmox VE
- **VM**: Ubuntu Server 22.04
- **Container Platform**: Docker with docker-compose
- **Storage**: Large capacity HDD passed through from host

## Hardware Configuration

- **Motherboard**: Gigabyte B650M K
- **Processor**: AMD Ryzen 5 7600
- **GPU**: MSI RX6800 (with GPU passthrough to desktop VM)
- **RAM**: 32GB (expandable to 64GB)
- **PSU**: 650W
- **Storage**: Multiple SSDs and HDDs for different purposes

## Virtual Machine Setup

### Ubuntu-Docker VM

- **OS**: Ubuntu Server 22.04.5 LTS
- **Purpose**: Docker container host
- **VM Label**: Ubuntu-docker

## Docker Configuration

### Basic Plex Setup

```yaml
version: '3.8'
services:
  plex:
    container_name: plex
    image: linuxserver/plex:latest
    network_mode: host
    environment:
      - PUID=1000
      - PGID=1000
      - VERSION=docker
      - TZ=America/Chicago
    volumes:
      - /mnt/media/config/plex:/config
      - /mnt/media/content:/media
    restart: unless-stopped
```

### Complete Media Stack

```yaml
version: '3.8'
services:
  # Media Server
  plex:
    container_name: plex
    image: linuxserver/plex:latest
    network_mode: host
    environment:
      - PUID=1000
      - PGID=1000
      - VERSION=docker
      - TZ=America/Chicago
    volumes:
      - /mnt/media/config/plex:/config
      - /mnt/media/content:/media
    restart: unless-stopped

  # Video Transcoding
  tdarr:
    container_name: tdarr
    image: haveagitgat/tdarr:latest
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Chicago
    volumes:
      - /mnt/media/config/tdarr:/config
      - /mnt/media/Movies:/media/Movies
      - /mnt/media/TV:/media/TV
      - /mnt/media/temp:/temp
    restart: unless-stopped

  # Download Management
  radarr:
    container_name: radarr
    image: linuxserver/radarr:latest
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Chicago
    volumes:
      - ./config/radarr:/config
      - /downloads:/downloads
      - /mnt/media/Movies:/movies
    restart: unless-stopped

  sonarr:
    container_name: sonarr
    image: linuxserver/sonarr:latest
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Chicago
    volumes:
      - ./config/sonarr:/config
      - /downloads:/downloads
      - /mnt/media/TV:/tv
    restart: unless-stopped

  # Download Client
  sabnzbd:
    container_name: sabnzbd
    image: linuxserver/sabnzbd:latest
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Chicago
    volumes:
      - ./config/sabnzbd:/config
      - /downloads:/downloads
    restart: unless-stopped

  # Additional Services
  overseerr:
    container_name: overseerr
    image: linuxserver/overseerr:latest
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Chicago
    volumes:
      - ./config/overseerr:/config
    restart: unless-stopped

  portainer:
    container_name: portainer
    image: portainer/portainer-ce:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    restart: unless-stopped

volumes:
  portainer_data:
```

## Storage Passthrough Process

### Proxmox Configuration

1. **Verify Storage Device**
   
   ```bash
   # Check available storage devices
   lsblk
   ```
2. **VirtIO Filesystem Passthrough**
- Used Proxmox GUI for VirtioFS configuration
- Shared host directory `/mnt/media` to VM
- Configured automatic mounting in VM
1. **Alternative CLI Method** (for reference)
   
   ```bash
   # Add mount point via CLI (if GUI not used)
   qm set <VM_ID> -mp0 /mnt/media,mp=/mnt/media
   ```

### VM Storage Configuration

```bash
# Create mount point directories
sudo mkdir -p /mnt/media/Movies
sudo mkdir -p /mnt/media/TV
sudo mkdir -p /mnt/media/config
sudo mkdir -p /mnt/media/temp

# Set proper permissions
sudo chown -R 1000:1000 /mnt/media
sudo chmod -R 755 /mnt/media
```

## Setup Process

### 1. Ubuntu Server Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y ca-certificates curl gnupg lsb-release

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
```

### 2. SSH Configuration

```bash
# Install SSH server
sudo apt install -y openssh-server

# Enable SSH service
sudo systemctl enable ssh
sudo systemctl start ssh

# Verify SSH status
sudo systemctl status ssh
```

### 3. Docker Services Deployment

```bash
# Create project directory
mkdir ~/media-stack
cd ~/media-stack

# Create docker-compose.yml (use configuration above)
nano docker-compose.yml

# Create config directories
mkdir -p config/{plex,radarr,sonarr,sabnzbd,overseerr,tdarr}

# Start services
docker-compose up -d

# Verify running containers
docker ps
```

## Troubleshooting

### Common Issues and Solutions

#### SSH Access Problems

```bash
# Check SSH service status
sudo systemctl status ssh

# Restart SSH if needed
sudo systemctl restart ssh

# Verify SSH port availability
sudo netstat -tlnp | grep :22
```

#### Docker Repository Issues

```bash
# Fix GPG key issues
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Re-add repository
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

sudo apt update
```

#### Volume Mount Issues

```bash
# Check mount points
mount | grep media

# Verify permissions
ls -la /mnt/media

# Test file creation
touch /mnt/media/test.txt
```

#### Container Permission Issues

```bash
# Check container logs
docker logs plex

# Verify user/group IDs
id

# Fix ownership if needed
sudo chown -R 1000:1000 /mnt/media
```

## File Management Integration

### Download Workflow

1. **Download Path**: `/downloads/intermediate` → `/downloads/completed`
2. **Import Process**: Radarr/Sonarr monitor completed downloads
3. **File Organization**: Automated sorting into proper media directories
4. **Transcoding**: Tdarr processes files for streaming optimization

### Storage Structure

```
/mnt/media/
├── Movies/
├── TV/
├── config/
│   ├── plex/
│   ├── radarr/
│   ├── sonarr/
│   └── tdarr/
└── temp/
```

### Tdarr Configuration

- **Input Directories**: `/mnt/media/Movies`, `/mnt/media/TV`
- **Temp Directory**: `/mnt/media/temp` (for transcoding workspace)
- **Plugins**: Classic plugin library for compatibility
- **Worker Nodes**: Configured for CPU-based transcoding

## Performance Optimization

### Resource Allocation

- Dedicated transcoding directory on fast storage
- Proper CPU/memory allocation for transcoding workloads
- Network optimization for large file transfers

### Monitoring

```bash
# Monitor container resource usage
docker stats

# Check system resources
htop
iotop

# Monitor disk usage
df -h
du -sh /mnt/media/*
```

### Maintenance

```bash
# Update containers
docker-compose pull
docker-compose up -d

# Clean up unused images
docker image prune

# Check logs
docker-compose logs -f plex
```

## Access and Management

### Service Access

- **Plex**: Web interface for media streaming
- **Radarr/Sonarr**: Automated download management
- **Overseerr**: User request interface
- **Portainer**: Docker container management
- **Tdarr**: Transcoding management

### Security Considerations

- Services configured with proper user/group isolation
- Network access controlled through Docker networking
- Regular security updates for base images
- File permissions properly configured

## Results

✅ **Successfully Deployed**:

- Plex media server with hardware storage access
- Automated download and organization pipeline
- Transcoding capability for format optimization
- Container management and monitoring
- Scalable architecture for additional services

## Lessons Learned

1. **Storage Passthrough**: VirtioFS provides excellent performance for media files
2. **Permission Management**: Consistent UID/GID across containers prevents access issues
3. **Volume Mapping**: Shared volume paths between containers enable seamless workflow
4. **Container Updates**: Regular updates ensure security and feature improvements
5. **Resource Planning**: Transcoding requires significant CPU resources and temporary storage
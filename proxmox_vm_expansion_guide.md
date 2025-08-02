# Proxmox VM Disk Expansion Guide

## System Overview

### Hardware Configuration
- **Motherboard**: Gigabyte B650M K
- **CPU**: AMD Ryzen 5 7600
- **GPU**: MSI RX6800 (with GPU passthrough)
- **RAM**: 64GB
- **PSU**: 650W
- **Storage**:
  - 1TB NVMe SSD
  - 2TB NVMe SSD  
  - 8TB HDD (for Plex media, mounted to media stack)

### Proxmox Setup
- **Host OS**: Proxmox VE
- **VM 1**: Ubuntu Server (Ubuntu-docker) - Docker containers for media stack
- **VM 2**: Pop OS - Desktop with GPU passthrough (expanded from 28GB → 78GB)
- **VM 3**: Manjaro KDE - Gaming desktop with GPU passthrough
- **VM 4**: Windows 11 - Currently stopped
- **VM 5**: Kali Linux - Currently stopped

### Storage Allocation
- **local**: 23GB/94GB - Proxmox system, templates, configs
- **local-lvm**: 152GB/1.67TB - VM virtual disks (main storage pool)
- **ssd1tb**: 23GB/94GB - Additional storage partition
- **8TB HDD**: Direct mount to media containers (Plex, Sonarr, Radarr, etc.)

## VM Expansion History

### 1. Pop OS VM Expansion (Previous)
**Problem**: VM ran out of space (100% usage at 28GB) - Ollama couldn't create directories

**Solution**:
- **Original size**: 28GB
- **Expanded to**: 78GB (+50GB)
- **Process**: Proxmox GUI resize → parted → resize2fs
- **File system**: ext4
- **Result**: ✅ Success - 50GB free space available

### 2. Manjaro KDE VM Expansion (Current)
**Problem**: Need space for Steam games library (60GB insufficient)

**Target**: Expand from 60GB to 1TB for gaming

## Step-by-Step Expansion Process

### Phase 1: Proxmox Virtual Disk Expansion

1. **Shutdown the target VM**
   ```bash
   # In Proxmox web interface or via CLI
   qm shutdown <VM_ID>
   ```

2. **Resize virtual disk in Proxmox GUI**
   - Navigate to: VM → Hardware → Hard Disk
   - Click "Resize disk"
   - Add desired space (for Manjaro: +940GB to reach 1TB total)

3. **Verify expansion**
   - Check that disk shows new size in Hardware tab
   - Boot the VM

### Phase 2: Partition and Filesystem Expansion

#### For btrfs filesystem (Manjaro case):

1. **Check current disk layout**
   ```bash
   sudo parted /dev/sda
   (parted) print
   ```
   
   **Expected output**:
   ```
   Model: QEMU QEMU HARDDISK (scsi)
   Disk /dev/sda: 1074GB
   Sector size (logical/physical): 512B/512B
   Partition Table: msdos
   Disk Flags: 
   
   Number  Start   End     Size    Type     File system  Flags
    1      1049kB  64.4GB  64.4GB  primary  btrfs        boot
   ```

2. **Resize partition to use full disk**
   ```bash
   (parted) resizepart 1 100%
   (parted) quit
   ```

3. **Resize btrfs filesystem**
   ```bash
   sudo btrfs filesystem resize max /
   ```
   
   **Expected output**:
   ```
   Resize device id 1 (/dev/sda1) from 60.00GiB to max
   ```

4. **Verify expansion**
   ```bash
   df -h /
   ```

#### For ext4 filesystem (Pop OS case):

1. **Resize partition with parted**
   ```bash
   sudo parted /dev/sda
   (parted) resizepart 1 100%
   (parted) quit
   ```

2. **Resize ext4 filesystem**
   ```bash
   sudo resize2fs /dev/sda1
   ```

## Results

### Manjaro KDE VM
- ✅ **Successfully expanded**: 60GB → 1TB
- ✅ **Available space**: ~940GB for Steam games
- ✅ **File system**: btrfs
- ✅ **No data loss**: Clean expansion
- ✅ **Steam ready**: Massive library space available

### Storage Pool Impact
- **Before**: 152GB used / 1.67TB total in local-lvm
- **After**: ~1092GB used / 1.67TB total in local-lvm  
- **Remaining**: ~580GB still available for other VMs

## Important Notes

### File System Considerations
- **btrfs**: Use `sudo btrfs filesystem resize max /`
- **ext4**: Use `sudo resize2fs /dev/sda1`
- **xfs**: Use `sudo xfs_growfs /`

### Safety Practices
- ✅ Always shutdown VM before resizing
- ✅ Verify Proxmox expansion succeeded before partition work
- ✅ Use appropriate filesystem resize command
- ✅ Check available space in storage pool before expanding
- ✅ Document all changes

### Troubleshooting
- If `parted` shows help instead of executing commands, you're in parted console
- Don't mix filesystem commands (resize2fs ≠ btrfs resize)
- Always verify partition table with `print` before resizing
- Check disk space with `df -h` after completion

## Docker Media Stack (Unchanged)
Located on Ubuntu-docker VM:
- Sonarr, Radarr, Lidarr (media management)
- Prowlarr (indexer management)  
- Overseerr (request management)
- Plex (media server)
- Uptime Kuma (monitoring)
- Pi-hole (DNS filtering)
- Portainer (container management)
- Tatuelli (ebook server)

**8TB HDD**: Direct mounted to containers, not managed by Proxmox storage

## Future Considerations
- Monitor storage pool usage as more VMs are expanded
- Consider ZFS for advanced features if rebuilding
- Document any additional VM expansions using this process
- Keep ~100-200GB free in local-lvm pool for overhead

---

**Last Updated**: August 2, 2025  
**Proxmox Version**: Latest  
**Process Tested On**: Pop OS (ext4), Manjaro KDE (btrfs)

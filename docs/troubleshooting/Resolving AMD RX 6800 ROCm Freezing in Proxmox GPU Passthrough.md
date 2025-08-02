# Resolving AMD RX 6800 ROCm Freezing in Proxmox GPU Passthrough

## Problem Statement

When attempting to run ROCm-based AI workloads (specifically Ollama with large language models) on an AMD RX 6800 GPU passed through to a virtual machine in Proxmox, the system would freeze immediately upon starting GPU compute tasks. This issue prevented the use of GPU acceleration for machine learning inference.

## System Configuration

### Hardware

- **CPU**: AMD Ryzen 5 7600
- **GPU**: MSI RX 6800 (16GB VRAM)
- **RAM**: 64GB
- **PSU**: 650W
- **Motherboard**: Gigabyte B650M-K

### Software Stack

- **Host**: Proxmox VE 8.x (Kernel 6.8.12-11-pve)
- **Guest OS**: Manjaro Linux (also tested with Pop!_OS)
- **AI Framework**: Ollama with ROCm backend
- **GPU Passthrough**: VFIO-PCI with IOMMU enabled

## Research and Root Cause Analysis

### Initial Symptoms

- Immediate system freeze when running `ollama run <model>`
- No error messages - complete system lockup requiring hard reset
- Issue occurred across multiple Linux distributions (Manjaro, Pop!_OS)
- ROCm detection working (`rocm-smi` functional)
- GPU passthrough successful (hardware detected properly)

### Research Findings

Through extensive research of similar issues, several key patterns emerged:

1. **RX 6800 Series Specific Issues**: Multiple reports of RX 6800 cards experiencing SMU (System Management Unit) timeouts with ROCm
2. **Power Management Conflicts**: AMD GPU power management features conflicting with virtualization
3. **ROCm + Virtualization Challenges**: Known compatibility issues between ROCm compute workloads and GPU passthrough

### Key Error Patterns Found in Research

- `amdgpu: SMU: I'm not done with your previous command`
- `ring gfx_0.0.0 timeout, signaled seq=X, emitted seq=Y`
- `Failed to enable gfxoff!`
- `GPU reset begin!`

## Solution Implementation

### Approach: Kernel Power Management Parameters

Based on research indicating power management conflicts, we implemented kernel parameters to disable problematic AMD GPU power features.

#### Step 1: Identify Boot Method

```bash
# Check boot method
proxmox-boot-tool status
ls /boot/efi/EFI/
```

Our system used UEFI + GRUB, so we used the GRUB configuration method.

#### Step 2: Apply Kernel Parameters

```bash
# Edit GRUB configuration
nano /etc/default/grub

# Modified line:
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt amdgpu.dpm=0 amdgpu.runpm=0 amdgpu.bapm=0 amdgpu.ppfeaturemask=0"

# Apply changes
update-grub
reboot
```

#### Step 3: Verify Implementation

```bash
# Confirm parameters are active
cat /proc/cmdline
```

**Expected output:**

```
BOOT_IMAGE=/boot/vmlinuz-6.8.12-11-pve root=/dev/mapper/pve-root ro quiet amd_iommu=on iommu=pt amdgpu.dpm=0 amdgpu.runpm=0 amdgpu.bapm=0 amdgpu.ppfeaturemask=0
```

## Results and Testing

### Success Metrics

The solution achieved significant improvement:

#### Before Implementation

- ❌ Immediate system freeze upon ROCm usage
- ❌ 0% success rate for GPU inference
- ❌ Unusable for AI workloads

#### After Implementation

- ✅ Stable GPU detection and initialization
- ✅ Successful model loading to GPU VRAM
- ✅ Extended periods of stable inference (minutes to hours)
- ✅ ~80% success rate for GPU workloads

### Evidence of Success

From Ollama service logs:

```log
time=2025-08-02T08:24:19.221-04:00 level=INFO msg="amdgpu is supported" gpu=GPU-b93ad0485e02f832 gpu_type=gfx1030
time=2025-08-02T08:24:19.221-04:00 level=INFO msg="inference compute" id=GPU-b93ad0485e02f832 library=rocm variant="" compute=gfx1030 driver=0.0 name=1002:73bf total="16.0 GiB" available="15.3 GiB"
load_backend: loaded ROCm backend from /usr/local/lib/ollama/libggml-hip.so
load_tensors: offloaded 33/33 layers to GPU
load_tensors: ROCm0 model buffer size = 4156.00 MiB
```

### Performance Achieved

- **Model**: dolphin-llama3:8b (8 billion parameters)
- **VRAM Usage**: ~5.4GB of 16GB available
- **Layer Offloading**: 33/33 layers successfully offloaded to GPU
- **Inference Speed**: Significantly faster than CPU-only inference

## Limitations and Ongoing Issues

### Remaining Challenges

- **Occasional Freezing**: System still freezes after extended use (improved from immediate to eventual)
- **Stability**: ~80% success rate vs. 100% desired
- **Recovery**: Freezes still require hard reset when they occur

### Root Cause Analysis

The partial success suggests the power management conflicts were the primary issue, but additional factors may contribute:

- ROCm + virtualization compatibility layers
- GPU memory management in virtualized environments
- Thermal or power delivery edge cases under sustained load

## Alternative Solutions Considered

### 1. LXC Container Approach

- **Pros**: Shared kernel, potentially more stable
- **Cons**: Cannot simultaneously use GPU for gaming VMs
- **Status**: Not implemented (conflicts with desktop use case)

### 2. Dual GPU Configuration

- **Pros**: 100% reliability, simultaneous AI + gaming
- **Cons**: Hardware cost, case space requirements
- **Status**: Recommended for production use

### 3. Bare Metal Installation

- **Pros**: Eliminates virtualization complexity
- **Cons**: Loses learning value of virtualization
- **Status**: Rejected for educational reasons

## Recommendations

### For Similar Issues

1. **Try kernel power management parameters first** - Low effort, high impact
2. **Research GPU-specific issues** - Different AMD generations have different quirks
3. **Consider LXC containers** for AI-only workloads
4. **Plan for dual GPU** if 100% reliability needed

### For Production Environments

- **Dual GPU setup recommended** for mission-critical workloads
- **Document boot methods** (UEFI vs BIOS, systemd-boot vs GRUB)
- **Test extensively** before deploying to production

## Technical Details

### Kernel Parameters Explained

- `amdgpu.dpm=0`: Disables Dynamic Power Management
- `amdgpu.runpm=0`: Disables Runtime Power Management
- `amdgpu.bapm=0`: Disables Bidirectional Application Power Management
- `amdgpu.ppfeaturemask=0`: Disables PowerPlay features

### Boot Configuration Methods

Different Proxmox installations may use:

- **UEFI + systemd-boot**: Uses `/etc/kernel/cmdline` + `proxmox-boot-tool refresh`
- **UEFI + GRUB**: Uses `/etc/default/grub` + `update-grub`
- **Legacy BIOS**: Uses GRUB configuration

## Conclusion

The kernel parameter approach successfully resolved the primary issue of immediate system freezing when using ROCm with AMD RX 6800 in Proxmox GPU passthrough. While not achieving 100% stability, the ~80% improvement represents a significant practical solution for development and learning environments.

This case study demonstrates the importance of:

- **Systematic problem-solving** approaches
- **Power management considerations** in virtualized GPU environments
- **Thorough research** of hardware-specific issues
- **Documenting both successes and limitations**

For environments requiring 100% stability, a dual GPU configuration remains the recommended approach.

## Repository Structure

```
├── README.md                    # This documentation
├── configs/
│   ├── grub-working             # Working GRUB configuration
│   └── proxmox-vm-config        # VM configuration that works
├── logs/
│   ├── ollama-success.log       # Successful GPU inference logs
│   └── ollama-failure.log       # Failure mode logs
└── scripts/
    └── setup-kernel-params.sh  # Automated parameter setup
```

## Contributing

If you’ve experienced similar issues or have additional solutions, please:

1. Fork this repository
2. Add your configuration details
3. Submit a pull request with your findings

## References

- [AMD ROCm Documentation](https://rocm.docs.amd.com/)
- [Proxmox GPU Passthrough Guide](https://pve.proxmox.com/wiki/PCI_Passthrough)
- [AMDGPU Kernel Parameters](https://dri.freedesktop.org/docs/drm/gpu/amdgpu.html)
- [Ollama ROCm Support](https://github.com/ollama/ollama)

-----

**Last Updated**: August 2025  
**System Tested**: Proxmox VE 8.x, AMD RX 6800, Kernel 6.8.12-11-pve
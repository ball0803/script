# Custom Helper Scripts for Proxmox VE

## 🚀 Overview

This repository provides custom helper scripts for Proxmox VE that allow you to create and manage LXC containers with your own installation scripts, independent of the community-scripts repository.

## 📦 What's Included

### Core System Files

- **`misc/build.func`** - Custom build functions (modified from ProxmoxVE)
- **`misc/core.func`** - Core helper functions
- **`misc/error_handler.func`** - Error handling and validation
- **`misc/tools.func`** - Additional utility functions
- **`misc/api.func`** - API integration functions
- **`misc/install.func`** - Installation helper functions
- **`misc/alpine-install.func`** - Alpine Linux installation functions
- **`misc/alpine-tools.func`** - Alpine Linux tools
- **`misc/cloud-init.func`** - Cloud-init configuration

### Application Scripts

#### SearXNG Installation
- **`ct/searxng.sh`** - Container creation script
- **`install/searxng-install.sh`** - Installation script
- **`ct/headers/searxng`** - ASCII art header

#### Scaffold Installation
- **`ct/scaffold.sh`** - Container creation script
- **`install/scaffold-install.sh`** - Installation script

### Documentation

- **`ct/README_searxng.md`** - SearXNG container documentation
- **`install/README_searxng.md`** - SearXNG installation documentation

## 🎯 Key Features

✅ **Repository Independence** - Use your own GitHub repository for installation scripts
✅ **Full Compatibility** - Compatible with Proxmox VE 7.x and 8.x
✅ **Custom Resource Allocation** - Configure CPU, RAM, and disk for each container
✅ **Network Configuration** - Support for IPv4, IPv6, VLAN, and MTU
✅ **Service Management** - Systemd services for all components
✅ **Security** - Firewall configuration and secure defaults
✅ **Update Functionality** - Easy updates via `--update` flag
✅ **Error Handling** - Comprehensive validation and error messages

## 🔧 How It Works

This system works by:

1. **Using your repository** for installation scripts instead of community-scripts
2. **Downloading scripts dynamically** from your GitHub repository
3. **Maintaining compatibility** with Proxmox VE patterns and conventions
4. **Providing full control** over the installation process

### Repository Configuration

The system is configured to use your repository:
```bash
https://raw.githubusercontent.com/ball0803/script/refs/heads/master/install/
```

To use your own repository, modify the URL in:
- `misc/build.func` (line 3220)
- Application container scripts

## 🚀 Quick Start

### Install SearXNG with MCP Integration

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ball0803/script/master/ct/searxng.sh)"
```

### Install Scaffold

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ball0803/script/master/ct/scaffold.sh)"
```

### Custom Resource Allocation

```bash
# High-performance configuration
VAR_CPU=4 VAR_RAM=8192 VAR_DISK=20 bash ct/searxng.sh

# Minimum configuration
VAR_CPU=2 VAR_RAM=4096 VAR_DISK=10 bash ct/searxng.sh
```

### Update Existing Installation

```bash
bash ct/searxng.sh --update
bash ct/scaffold.sh --update
```

## 📋 Configuration Options

### Resource Allocation

| Variable | Description | Default |
|----------|-------------|---------|
| `VAR_CPU` | Number of CPU cores | 2 |
| `VAR_RAM` | Memory in MB | 4096 |
| `VAR_DISK` | Disk size in GB | 10 |
| `VAR_OS` | Operating system | debian |
| `VAR_VERSION` | OS version | 12 |

### Network Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `VAR_NET` | IP address | dhcp |
| `VAR_GATEWAY` | Gateway IP | (auto) |
| `VAR_VLAN` | VLAN tag | (none) |
| `VAR_MTU` | MTU size | (auto) |
| `VAR_IPV6_METHOD` | IPv6 method | auto |

### Example: Static IP Configuration

```bash
VAR_NET=192.168.1.100/24 VAR_GATEWAY=192.168.1.1 bash ct/searxng.sh
```

### Example: VLAN Configuration

```bash
VAR_VLAN=100 bash ct/searxng.sh
```

## 🔧 Technical Details

### Software Stack

| Component | Purpose |
|-----------|---------|
| **Proxmox VE** | Container host platform |
| **LXC** | Container technology |
| **Debian 12** | Default container OS |
| **Systemd** | Service management |
| **Nginx** | Reverse proxy |
| **UFW** | Firewall management |

### How It Differs from Community-Scripts

1. **Repository Independence**: Uses your own repository instead of community-scripts
2. **Custom Installation Scripts**: You control what gets installed
3. **Same Patterns**: Maintains compatibility with Proxmox VE conventions
4. **Full Control**: You have complete control over the installation process

## 📚 Documentation

### Getting Started

- [SearXNG Container Documentation](ct/README_searxng.md)
- [SearXNG Installation Documentation](install/README_searxng.md)

### Technical Reference

- [Core Functions](misc/core.func)
- [Build Functions](misc/build.func)
- [Error Handling](misc/error_handler.func)

## 🎯 Use Cases

### For Developers
- Create custom application installations
- Test new configurations
- Develop custom Proxmox VE scripts

### For System Administrators
- Deploy applications with your own scripts
- Maintain control over installation process
- Use your own repository for updates

### For Organizations
- Host your own installation scripts
- Maintain internal applications
- Customize deployments for your needs

## 📞 Support

### Official Documentation

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [LXC Documentation](https://linuxcontainers.org/)

### Community Resources

- [Proxmox VE Forum](https://forum.proxmox.com/)
- [Linux Containers Forum](https://discuss.linuxcontainers.org/)

## 🎉 Success Metrics

- ✅ **Files**: 19+ helper functions and scripts
- ✅ **Lines of Code**: 13,000+ lines
- ✅ **Compatibility**: Proxmox VE 7.x and 8.x
- ✅ **Independence**: No dependency on external repositories

## 🚀 Next Steps

1. **Customize** the repository URL to use your own GitHub repository
2. **Create** your own installation scripts
3. **Test** the system with your applications
4. **Deploy** to production
5. **Maintain** your custom scripts

## 📝 License

This project is based on the community-scripts Proxmox VE helper functions and is licensed under the MIT license.

---

**Project**: Custom Helper Scripts for Proxmox VE
**Status**: Active Development
**Date**: January 5, 2026
**Repository**: https://github.com/ball0803/script

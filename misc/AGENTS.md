# AGENTS.md

## Function Libraries

### Purpose
Reusable bash functions for scripts

### Structure
```
./misc/
├── alpine-install.func
├── alpine-tools.func
├── api.func
├── build.func
├── cloud-init.func
├── core.func
├── error_handler.func
├── install.func
└── tools.func
```

### Key Functions

**core.func**
- `header_info`: Display app header
- `variables`: Set default variables
- `color`: Initialize colors
- `catch_errors`: Error handling

**build.func**
- `start`: Begin container creation
- `build_container`: Create LXC container
- `description`: Show completion message

**install.func**
- `setting_up_container`: Setup container
- `network_check`: Verify network
- `update_os`: Update system
- `import_local_ip`: Get local IP

**error_handler.func**
- `msg_error`: Error messages
- `msg_warn`: Warning messages
- `msg_info`: Info messages
- `msg_ok`: Success messages

### Usage

```bash
# Source in scripts
source <(curl -fsSL https://raw.githubusercontent.com/
community-scripts/ProxmoxVE/main/misc/build.func)

# Or locally
source ./misc/build.func
```

### Notes

- Functions used across all scripts
- Standardized error handling
- Color-coded output
- Consistent messaging format

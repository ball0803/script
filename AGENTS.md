# AGENTS.md

## Project Overview
Proxmox VE Helper-Scripts - Bash automation for container/VM management

## Structure
```
./
├── ct/              # Container scripts (4 scripts)
├── install/         # Installation scripts (4 scripts)
├── misc/            # Function libraries (9 files)
└── ProxmoxVE/      # Main repository (970 files)
```

## Key Directories

- `./ct`: Container creation scripts
- `./install`: Installation scripts
- `./misc`: Function libraries
- `./ProxmoxVE`: Main repository (404 ct + 402 install scripts)

## Conventions

- No interactive prompts
- No hardcoded credentials
- 2-space indent
- Function libraries in misc/
- Standardized script structure

## Anti-Patterns

- Hardcoded IPs, passwords
- Interactive user input
- Complex logic in scripts
- Large file operations

## Commands

```bash
# Build container
bash ct/scaffold.sh

# Install dependencies
bash install/scaffold-install.sh

# Test syntax
bash -n ct/*.sh

# Check dependencies
grep -E "(apt install|docker)" install/*.sh
```

## Notes/Gotchas

- Functions sourced from community-scripts
- Docker required for most scripts
- Proxmox VE 7.x/8.x required
- Test on staging before production

# Agent Guidelines

## Project Overview

Ansible playbooks for automated, hardened OpenClaw installation on Debian/Ubuntu and macOS systems.

## Architecture

Two independent, self-contained playbooks with zero shared code:
- `playbook-linux.yml` + `roles/linux/` - Debian/Ubuntu
- `playbook-macos.yml` + `roles/macos/` - macOS

## Key Principles

1. **Security First**: Firewall must be configured before Docker installation
2. **One Command Install**: `curl | bash` should work out of the box
3. **Localhost Only**: All container ports bind to 127.0.0.1
4. **Defense in Depth**: UFW + DOCKER-USER + localhost binding + non-root container
5. **Complete OS separation**: No cross-OS conditionals, no shared role code

## Critical Components

### Task Order
Docker must be installed **before** firewall configuration.

Task order in `roles/linux/tasks/main.yml` (and `roles/macos/tasks/main.yml`):
```yaml
- system-tools.yml  # System packages + shell config
- tailscale.yml     # VPN setup
- user.yml          # Create system user
- docker.yml        # Install Docker (creates /etc/docker)
- firewall.yml      # Configure UFW + daemon.json (needs /etc/docker to exist)
- nodejs.yml        # Node.js + pnpm
- openclaw.yml      # App install
```

Reason: `firewall.yml` writes `/etc/docker/daemon.json` and restarts Docker service.

### DOCKER-USER Chain (Linux only)
Located in `/etc/ufw/after.rules`. Uses dynamic interface detection (not hardcoded `eth0`).

**Never** use `iptables: false` in Docker daemon config - this would break container networking.

### Port Binding
Always use `127.0.0.1:HOST_PORT:CONTAINER_PORT` in docker-compose.yml, never `HOST_PORT:CONTAINER_PORT`.

## Code Style

### Ansible
- Use loops instead of repeated tasks
- No `become_user` (playbook already runs as root)
- Use `community.docker.docker_compose_v2` (not deprecated `docker_compose`)
- Always specify collections in `requirements.yml`
- No cross-OS conditionals within a role (each role is OS-specific)

### Docker
- Multi-stage builds if needed
- USER directive for non-root
- Proper healthchecks (test the app, not just Node)
- Use `docker compose` (V2) not `docker-compose` (V1)
- No `version:` in compose files

### Templates
- Use variables for all paths/ports
- Add comments explaining security decisions
- Keep jinja2 logic simple

## Testing Checklist

Before committing changes:

```bash
# 1. Syntax check both playbooks
ansible-playbook playbook-linux.yml --syntax-check
ansible-playbook playbook-macos.yml --syntax-check

# 2. Dry run
ansible-playbook playbook-linux.yml --check

# 3. Full install (on test VM)
curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash

# 4. Verify security (Linux)
sudo ufw status verbose
sudo iptables -L DOCKER-USER -n
sudo ss -tlnp  # Only SSH + localhost should listen

# 5. External port scan
nmap -p- TEST_SERVER_IP  # Only port 22 should be open

# 6. Test isolation
sudo docker run -p 80:80 nginx
curl http://TEST_SERVER_IP:80  # Should fail
curl http://localhost:80        # Should work

# 7. Verify no cross-OS references
grep -r "ansible_os_family" roles/   # should return nothing
grep -r "is_macos\|is_linux\|is_debian" roles/  # should return nothing
```

## Common Mistakes to Avoid

1. Installing Docker before configuring firewall
2. Using `0.0.0.0` port binding
3. Hardcoding network interface names (use dynamic detection)
4. Setting `iptables: false` in Docker daemon
5. Running container as root
6. Using deprecated `docker-compose` (V1)
7. Forgetting to add collections to requirements.yml
8. Adding cross-OS conditionals inside a role (put OS logic in the correct role instead)

## Documentation

### User-Facing
- **README.md**: Installation, quick start, basic management
- **docs/**: Technical details, architecture, troubleshooting

### Developer-Facing
- **AGENTS.md**: This file - guidelines for AI agents/contributors
- Code comments: Explain *why*, not *what*

Keep docs concise. No progress logs, no refactoring summaries.

## File Locations

### Host System
```
/home/openclaw/.openclaw/   # Config and data (Linux)
/Users/openclaw/.openclaw/  # Config and data (macOS)
/etc/systemd/system/openclaw.service  # Linux only
/etc/docker/daemon.json     # Linux only
/etc/ufw/after.rules        # Linux only
```

### Repository
```
playbook-linux.yml   # Linux entry point
playbook-macos.yml   # macOS entry point
install.sh           # Auto-detecting installer
run-playbook.sh      # Auto-detecting runner

roles/linux/         # Self-contained Linux role
├── tasks/           # Ansible tasks (order matters!)
├── templates/       # Jinja2 configs (daemon.json, systemd, vimrc)
├── defaults/        # Variables
├── handlers/        # Service restart handlers
└── files/           # Shell scripts

roles/macos/         # Self-contained macOS role
├── tasks/           # Ansible tasks (order matters!)
├── templates/       # Jinja2 configs
├── defaults/        # Variables
├── handlers/        # Empty (no systemd)
└── files/           # Shell scripts

docs/                # Technical documentation
requirements.yml     # Ansible Galaxy collections
```

## Security Notes

### Why UFW + DOCKER-USER? (Linux)
Docker bypasses UFW by default. DOCKER-USER chain is evaluated first, allowing us to block before Docker sees the traffic.

### Why Fail2ban? (Linux)
SSH is exposed to the internet. Fail2ban automatically bans IPs after 5 failed attempts for 1 hour.

### Why Unattended-Upgrades? (Linux)
Security patches should be applied promptly. Automatic security-only updates reduce vulnerability windows.

### Why Scoped Sudo? (Linux)
The openclaw user only needs to manage its own service and Tailscale. Full root access would be dangerous if the app is compromised.

### Why Localhost Binding?
Defense in depth. If DOCKER-USER fails, localhost binding prevents external access.

### Why Non-Root Container?
Least privilege. Limits damage if container is compromised.

### Why Systemd? (Linux)
Clean lifecycle, auto-start, logging integration.

### Known Limitations
- **macOS**: No launchd service, basic firewall. Test thoroughly.
- **IPv6**: Disabled in Docker. Review if your network uses IPv6.
- **curl | bash**: Inherent risks. For production, clone and audit first.

## Making Changes

### Adding a New Task
1. Add to the appropriate role (`roles/linux/tasks/` or `roles/macos/tasks/`)
2. Update `main.yml` if new task file
3. Test with `--check` first
4. Verify idempotency (can run multiple times safely)

### Changing Firewall Rules (Linux)
1. Test on disposable VM first
2. Always keep SSH accessible
3. Update `docs/security.md` with changes
4. Verify with external port scan

### Updating Docker Config (Linux)
1. Changes to `daemon.json.j2` trigger Docker restart (via handler)
2. Test container networking after restart
3. Verify DOCKER-USER chain still works

## Version Management

- Use semantic versioning for releases
- Tag releases in git
- Update CHANGELOG.md with user-facing changes
- No version numbers in code (use git tags)

## Support Channels

- OpenClaw issues: https://github.com/openclaw/openclaw
- This installer: https://github.com/openclaw/openclaw-ansible

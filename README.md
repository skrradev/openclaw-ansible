# OpenClaw Ansible Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lint](https://github.com/openclaw/openclaw-ansible/actions/workflows/lint.yml/badge.svg)](https://github.com/openclaw/openclaw-ansible/actions/workflows/lint.yml)
[![Ansible](https://img.shields.io/badge/Ansible-2.14+-blue.svg)](https://www.ansible.com/)
[![Multi-OS](https://img.shields.io/badge/OS-Debian%20%7C%20Ubuntu%20%7C%20macOS-orange.svg)](https://www.debian.org/)

Automated, hardened installation of [OpenClaw](https://github.com/openclaw/openclaw) with Docker, Homebrew, and Tailscale VPN support for Linux and macOS.

## Features

- **Firewall-first**: UFW (Linux) + Application Firewall (macOS) + Docker isolation
- **Fail2ban**: SSH brute-force protection out of the box
- **Auto-updates**: Automatic security patches via unattended-upgrades
- **Tailscale VPN**: Secure remote access without exposing services
- **Homebrew**: Package manager for both Linux and macOS
- **Docker**: Docker CE (Linux) / Docker Desktop (macOS)
- **Multi-OS Support**: Debian, Ubuntu, and macOS
- **Direct Ansible install**: Explicit playbook-driven setup
- **Auto-configuration**: DBus, systemd, environment setup
- **pnpm installation**: Uses `pnpm install -g openclaw@<openclaw_version>` (default: `latest`)

## Quick Start

### Release Mode (Recommended)

Install OpenClaw from npm via Ansible (default version is `latest`):

```bash
git clone https://github.com/skrradev/openclaw-ansible.git
cd openclaw-ansible
ansible-galaxy collection install -r requirements.yml

# Linux
ansible-playbook playbook-linux.yml
# macOS
ansible-playbook playbook-macos.yml```

### Development Mode

Install from source for development or testing:

```bash
# Clone the installer
git clone https://github.com/openclaw/openclaw-ansible.git
cd openclaw-ansible

# Install in development mode (Linux)
ansible-playbook playbook-linux.yml --ask-become-pass -e openclaw_install_mode=development

# Install in development mode (macOS)
ansible-playbook playbook-macos.yml --ask-become-pass -e openclaw_install_mode=development
```

## What Gets Installed

- Tailscale (mesh VPN)
- UFW firewall (SSH + Tailscale ports only)
- Docker CE + Compose V2 (for sandboxes)
- Node.js 22.x + pnpm
- OpenClaw on host (not containerized)
- Systemd service (auto-start)

## Post-Install

After installation completes, switch to the openclaw user:

```bash
sudo su - openclaw
```

Then run the quick-start onboarding wizard:

```bash
openclaw onboard --install-daemon
```

This will:
- Guide you through the setup wizard
- Configure your messaging provider (WhatsApp/Telegram/Signal)
- Install and start the daemon service

### Alternative Manual Setup

```bash
# Configure manually
openclaw configure

# Login to provider
openclaw providers login

# Test gateway
openclaw gateway

# Install as daemon
openclaw daemon install
openclaw daemon start

# Check status
openclaw status
openclaw logs
```

### Systemd Scope

- `openclaw` has scoped sudo for `openclaw` service management only.
- `sudo systemctl daemon-reload` is intentionally not granted to `openclaw`.
- If `openclaw` creates user-level services, use `systemctl --user`:

```bash
mkdir -p ~/.config/systemd/user
# place your user unit file in ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now my-worker.service
systemctl --user status my-worker.service
```

## Installation Modes

### Release Mode (Default)
- Installs via `pnpm install -g openclaw@<openclaw_version>`
- `openclaw_version` defaults to `latest` (you can pin a version)
- Automatic updates when `openclaw_version: latest`
- **Recommended for production**

### Development Mode
- Clones from `https://github.com/openclaw/openclaw.git`
- Builds from source with `pnpm build`
- Symlinks binary to `~/.local/bin/openclaw`
- Adds helpful aliases:
  - `openclaw-rebuild` - Rebuild after code changes
  - `openclaw-dev` - Navigate to repo directory
  - `openclaw-pull` - Pull, install deps, and rebuild
- **Recommended for development and testing**

Enable with: `-e openclaw_install_mode=development`

## Security

- **Public ports**: SSH (22), Tailscale (41641/udp) only
- **Fail2ban**: SSH brute-force protection (5 attempts -> 1 hour ban)
- **Automatic updates**: Security patches via unattended-upgrades
- **Docker isolation**: Containers can't expose ports externally (DOCKER-USER chain)
- **Non-root**: OpenClaw runs as unprivileged user
- **Scoped sudo**: Limited to service management (not full root)
- **Systemd hardening**: NoNewPrivileges, PrivateTmp, ProtectSystem

Verify: `nmap -p- YOUR_SERVER_IP` should show only port 22 open.

### Security Note

For high-security environments, audit before running:

```bash
git clone https://github.com/openclaw/openclaw-ansible.git
cd openclaw-ansible
# Review playbook-linux.yml and roles/linux/
ansible-playbook playbook-linux.yml --check --diff  # Dry run
ansible-playbook playbook-linux.yml```

### Multi-Phase Linux Hardening

Use explicit playbooks for each phase:

```bash
# 1) Baseline install (safe defaults, non-locking SSH hardening)
ansible-playbook playbook-linux.yml --ask-become-pass -e @vars.yml

# 2) Strict SSH hardening (key-only auth + no root login)
ansible-playbook playbook-linux-ssh-strict.yml --ask-become-pass -e @vars.yml

# 3) Optional: lock SSH to tailscale0 only
ansible-playbook playbook-linux-ssh-lockdown.yml```

For cloud images (AWS/GCP), point to the existing admin user (no creation):

```yaml
admin_user: "ubuntu"  # or debian/ec2-user, based on image
```

## Documentation

- [Configuration Guide](docs/configuration.md) - All configuration options
- [Development Mode](docs/development-mode.md) - Build from source
- [Security Architecture](docs/security.md) - Security details
- [Technical Details](docs/architecture.md) - Architecture overview
- [Troubleshooting](docs/troubleshooting.md) - Common issues
- [Agent Guidelines](AGENTS.md) - AI agent instructions

## Requirements

### Linux (Debian/Ubuntu)
- Debian 11+ or Ubuntu 20.04+
- Root/sudo access
- Internet connection

### macOS
- macOS 11 (Big Sur) or later
- Homebrew will be installed automatically
- Admin/sudo access
- Internet connection

## What Gets Installed

### Common (All OS)
- Homebrew package manager
- Node.js 22.x + pnpm
- OpenClaw via `pnpm install -g openclaw@<openclaw_version>` (default: `latest`)
- Essential development tools
- Git, zsh, oh-my-zsh

### Linux-Specific
- Docker CE + Compose V2
- UFW firewall (configured)
- Tailscale VPN
- systemd service

### macOS-Specific
- Docker Desktop (via Homebrew Cask)
- Application Firewall
- Tailscale app

## Manual Installation

### Release Mode (Default)

```bash
# Install dependencies
sudo apt update && sudo apt install -y ansible git

# Clone repository
git clone https://github.com/openclaw/openclaw-ansible.git
cd openclaw-ansible

# Install Ansible collections
ansible-galaxy collection install -r requirements.yml

# Run installation (Linux)
ansible-playbook playbook-linux.yml
# Run installation (macOS)
ansible-playbook playbook-macos.yml```

### Development Mode

Build from source for development:

```bash
# Linux:
ansible-playbook playbook-linux.yml --ask-become-pass -e openclaw_install_mode=development

# macOS:
ansible-playbook playbook-macos.yml --ask-become-pass -e openclaw_install_mode=development
```

This will:
- Clone openclaw repo to `~/code/openclaw`
- Run `pnpm install` and `pnpm build`
- Symlink binary to `~/.local/bin/openclaw`
- Add development aliases to shell config

## Configuration Options

All configuration variables can be found in the role defaults:
- Linux: [`roles/linux/defaults/main.yml`](roles/linux/defaults/main.yml)
- macOS: [`roles/macos/defaults/main.yml`](roles/macos/defaults/main.yml)

You can override them in three ways:

### 1. Via Command Line

```bash
# Linux: development mode + openclaw SSH key
ansible-playbook playbook-linux.yml --ask-become-pass \
  -e openclaw_install_mode=development \
  -e "openclaw_ssh_keys=['ssh-ed25519 AAAAC3... user@host']"

# Linux: create admin user with admin + openclaw SSH keys
ansible-playbook playbook-linux.yml --ask-become-pass \
  -e '{"admin_user":"adminops","admin_ssh_keys":["ssh-ed25519 AAAA... admin@laptop"],"openclaw_ssh_keys":["ssh-ed25519 AAAA... openclaw@laptop"]}'

# Linux: strict SSH hardening for cloud default user
ansible-playbook playbook-linux-ssh-strict.yml --ask-become-pass \
  -e admin_user=ubuntu
```

### 2. Via Variables File

```bash
# Copy template
cp vars.example.yml vars.yml

# Edit vars.yml for your environment
$EDITOR vars.yml

# Use it (Linux)
ansible-playbook playbook-linux.yml --ask-become-pass -e @vars.yml

# Use it (macOS)
ansible-playbook playbook-macos.yml --ask-become-pass -e @vars.yml
```

`vars.example.yml` includes cloud defaults (`admin_user`) and notes for bare-metal admin bootstrap.

### 3. Edit Defaults Directly

Edit the role defaults before running the playbook.

### Available Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `openclaw_user` | `openclaw` | System user name |
| `openclaw_home` | `/home/openclaw` (Linux) / `/Users/openclaw` (macOS) | User home directory |
| `openclaw_install_mode` | `release` | `release` or `development` |
| `openclaw_version` | `latest` | OpenClaw npm version for release mode |
| `openclaw_ssh_keys` | `[]` | List of SSH public keys |
| `admin_user` | `""` | Admin username — with `admin_ssh_keys`: creates user (bare metal); without: assumes existing (cloud) |
| `admin_ssh_keys` | `[]` | SSH public keys for `admin_user` (triggers user creation when non-empty) |
| `openclaw_repo_url` | `https://github.com/openclaw/openclaw.git` | Git repository (dev mode) |
| `openclaw_repo_branch` | `main` | Git branch (dev mode) |
| `tailscale_authkey` | `""` | Tailscale auth key for auto-connect |
| `nodejs_version` | `22.x` (Linux) / `22` (macOS) | Node.js version to install |
| `timezone` | `""` (Linux) | Linux timezone (fallback: `UTC`) |

### Common Configuration Examples

#### Cloud (AWS/GCP) — existing `ubuntu` user

```bash
# Without Tailscale
ansible-playbook playbook-linux.yml \
  -e admin_user=ubuntu

# With Tailscale auto-connect (get key: https://login.tailscale.com/admin/settings/keys)
ansible-playbook playbook-linux.yml \
  -e admin_user=ubuntu \
  -e tailscale_authkey=tskey-auth-xxxxxxxxxxxxx

# With explicit timezone
ansible-playbook playbook-linux.yml \
  -e admin_user=ubuntu \
  -e timezone=Europe/Berlin

# Pin OpenClaw release version
ansible-playbook playbook-linux.yml \
  -e admin_user=ubuntu \
  -e openclaw_version=0.9.4
```

#### Bare Metal (Hetzner/Dedicated) — create admin user

```bash
# Without Tailscale
ansible-playbook playbook-linux.yml \
  -e '{"admin_user":"admin","admin_ssh_keys":["ssh-ed25519 AAAA... you@laptop"]}'

# With Tailscale auto-connect
ansible-playbook playbook-linux.yml \
  -e '{"admin_user":"admin","admin_ssh_keys":["ssh-ed25519 AAAA... you@laptop"]}' \
  -e tailscale_authkey=tskey-auth-xxxxxxxxxxxxx
```

#### Post-Install Hardening

```bash
# Strict SSH (key-only, no root login) — requires admin_user
ansible-playbook playbook-linux-ssh-strict.yml \
  -e admin_user=ubuntu

# Lock SSH to Tailscale only (run after `tailscale up`)
ansible-playbook playbook-linux-ssh-lockdown.yml```

#### Development Mode

```bash
ansible-playbook playbook-linux.yml \
  -e admin_user=ubuntu \
  -e openclaw_install_mode=development
```

## License

MIT - see [LICENSE](LICENSE)

## Support

- OpenClaw: https://github.com/openclaw/openclaw
- This installer: https://github.com/openclaw/openclaw-ansible/issues

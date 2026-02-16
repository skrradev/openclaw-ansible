---
title: Architecture
description: Technical implementation details
---

# Architecture

## Component Overview

```
┌─────────────────────────────────────────┐
│ UFW Firewall (SSH only)                 │
└──────────────┬──────────────────────────┘
               │
┌──────────────┴──────────────────────────┐
│ DOCKER-USER Chain (iptables)            │
│ Blocks all external container access    │
└──────────────┬──────────────────────────┘
               │
┌──────────────┴──────────────────────────┐
│ OpenClaw Host Service                    │
│ User: openclaw                           │
│ Managed by systemd                       │
└──────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Docker Daemon (sandbox workloads)       │
│ - Non-root containers                    │
│ - Localhost-only binding                 │
└─────────────────────────────────────────┘
```

## File Structure

```
/home/openclaw/.openclaw/
├── config.yml
├── sessions/
└── credentials/

/etc/systemd/system/
└── openclaw.service

/etc/docker/
└── daemon.json

/etc/ufw/
└── after.rules (DOCKER-USER chain)
```

## Service Management

OpenClaw runs as a systemd service on the host:

```bash
systemd → openclaw gateway (host process)
```

## Installation Flow (Linux)

> The project uses separate playbooks and roles per OS:
> - **Linux**: `playbook-linux.yml` with `roles/linux/`
> - **macOS**: `playbook-macos.yml` with `roles/macos/`

1. **System Tools** (`roles/linux/tasks/system-tools.yml`)
   - Install apt packages, oh-my-zsh, git config

2. **Tailscale Setup** (`roles/linux/tasks/tailscale.yml`)
   - Add Tailscale repository
   - Install Tailscale package
   - Display connection instructions

3. **User Setup** (`roles/linux/tasks/admin-user.yml` + `roles/linux/tasks/user.yml`)
   - Optional admin bootstrap user (bare metal)
   - Create `openclaw` system user

4. **Docker Installation** (`roles/linux/tasks/docker.yml`)
   - Install Docker CE + Compose V2
   - Add user to docker group
   - Create `/etc/docker` directory

5. **Firewall Setup** (`roles/linux/tasks/firewall.yml`)
   - Install UFW
   - Configure DOCKER-USER chain
   - Configure Docker daemon (`/etc/docker/daemon.json`)
   - Allow SSH (22/tcp) and Tailscale (41641/udp)

6. **Node.js Installation** (`roles/linux/tasks/nodejs.yml`)
   - Add NodeSource repository
   - Install Node.js 22.x
   - Install pnpm globally

7. **OpenClaw Setup** (`roles/linux/tasks/openclaw.yml`)
   - Create OpenClaw directories
   - Install OpenClaw in release or development mode
   - Prepare runtime environment for `openclaw` user

## Key Design Decisions

### Why UFW + DOCKER-USER?

Docker manipulates iptables directly, bypassing UFW. The DOCKER-USER chain is evaluated before Docker's FORWARD chain, allowing us to block traffic before Docker sees it.

### Why Localhost Binding?

Defense in depth. Even if DOCKER-USER fails, localhost binding prevents external access.

### Why Systemd Service?

- Auto-start on boot
- Clean lifecycle management
- Integration with system logs
- Dependency management (after Docker)

### Why Non-Root Container?

Principle of least privilege. If container is compromised, attacker has limited privileges.

## Ansible Task Order (Linux)

```
roles/linux/tasks/main.yml
├── system-tools.yml (apt packages, oh-my-zsh, git config)
├── tailscale.yml (VPN setup)
├── admin-user.yml (optional admin bootstrap user)
├── user.yml (create openclaw user)
├── docker.yml (install Docker, create /etc/docker)
├── firewall.yml (configure UFW + Docker daemon)
├── nodejs.yml (Node.js + pnpm)
└── openclaw.yml (host setup)
```

Order matters: Docker must be installed before firewall configuration because:
1. `/etc/docker` directory must exist for `daemon.json`
2. Docker service must exist to be restarted after config changes

## Ansible Task Order (macOS)

```
roles/macos/tasks/main.yml
├── system-tools.yml (brew packages, oh-my-zsh, git config)
├── tailscale.yml (VPN setup)
├── user.yml (create openclaw user)
├── docker.yml (Docker Desktop via Homebrew)
├── firewall.yml (Application Firewall)
├── nodejs.yml (Node.js + pnpm)
└── openclaw.yml (container setup)
```

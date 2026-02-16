---
title: Installation Guide
description: Detailed installation and configuration instructions
---

# Installation Guide

## Quick Install

```bash
git clone https://github.com/openclaw/openclaw-ansible.git
cd openclaw-ansible
ansible-galaxy collection install -r requirements.yml

# Linux
ansible-playbook playbook-linux.yml --ask-become-pass

# macOS
ansible-playbook playbook-macos.yml --ask-become-pass
```

## Manual Installation

### Prerequisites

```bash
sudo apt update
sudo apt install -y ansible git
```

### Clone and Run

```bash
git clone https://github.com/openclaw/openclaw-ansible.git
cd openclaw-ansible

# Install Ansible collections
ansible-galaxy collection install -r requirements.yml

# Run playbook (Linux)
ansible-playbook playbook-linux.yml --ask-become-pass

# Or for macOS
ansible-playbook playbook-macos.yml --ask-become-pass
```

## Post-Installation

### 1. Connect to Tailscale

```bash
# Interactive login
sudo tailscale up

# Or with auth key for automation
sudo tailscale up --authkey tskey-auth-xxxxx

# Check status
sudo tailscale status
```

Get auth keys from: https://login.tailscale.com/admin/settings/keys

### 2. Configure OpenClaw

```bash
# Edit config
sudo nano /home/openclaw/.openclaw/config.yml

# Key settings to configure:
# - provider: whatsapp/telegram/signal
# - phone: your number
# - ai.provider: anthropic/openai
# - ai.model: claude-3-5-sonnet-20241022
```

### 3. Login to Provider

```bash
# Switch to openclaw user
sudo su - openclaw

# Login (prompts for provider auth)
openclaw providers login

# Verify status and logs
openclaw status
openclaw logs
```

## Service Management

### Systemd Commands

```bash
# Start/stop/restart
sudo systemctl start openclaw
sudo systemctl stop openclaw
sudo systemctl restart openclaw

# View status
sudo systemctl status openclaw

# Enable/disable auto-start
sudo systemctl enable openclaw
sudo systemctl disable openclaw
```

### OpenClaw Commands

```bash
# Run as openclaw user
sudo su - openclaw
openclaw status
openclaw logs
openclaw gateway
```

### Firewall Management

```bash
# View UFW status
sudo ufw status verbose

# Add custom rule
sudo ufw allow 8080/tcp comment 'Custom service'
sudo ufw reload

# View Docker isolation
sudo iptables -L DOCKER-USER -n -v
```

## Accessing OpenClaw

OpenClaw's web interface runs on port 3000 (localhost only).

### Via Tailscale + SSH Tunnel

```bash
# From your machine
ssh -L 3000:localhost:3000 USER@TAILSCALE_IP
# Then browse to: http://localhost:3000
```

### Via SSH Tunnel

```bash
ssh -L 3000:localhost:3000 user@server
# Then browse to: http://localhost:3000
```

## Verification

### Security Check

```bash
# Check open ports (should show only SSH + Tailscale)
sudo ss -tlnp

# External port scan (only port 22 should be open)
nmap -p- YOUR_SERVER_IP

# Test container isolation
sudo docker run -d -p 80:80 --name test-nginx nginx
curl http://YOUR_SERVER_IP:80  # Should fail
curl http://localhost:80        # Should work
sudo docker rm -f test-nginx
```

### UFW Status

```bash
sudo ufw status verbose

# Expected output:
# Status: active
# To                         Action      From
# --                         ------      ----
# 22/tcp                     ALLOW IN    Anywhere
# 41641/udp                  ALLOW IN    Anywhere
```

### Tailscale Status

```bash
sudo tailscale status

# Expected output:
# 100.x.x.x    hostname    user@        linux   -
```

## Uninstall

```bash
# Stop services
sudo systemctl stop openclaw
sudo systemctl disable openclaw
sudo tailscale down

# Remove service and data
sudo rm /etc/systemd/system/openclaw.service
sudo systemctl daemon-reload
sudo rm -rf /home/openclaw/.openclaw
sudo rm -rf /home/openclaw/.local/share/pnpm
sudo rm -rf /home/openclaw/.local/bin/openclaw

# Remove packages (optional)
sudo apt remove --purge tailscale docker-ce docker-ce-cli containerd.io docker-compose-plugin nodejs

# Remove user (optional)
sudo userdel -r openclaw

# Reset firewall (optional)
sudo ufw disable
sudo ufw --force reset
```

## Advanced Configuration

### Gateway Configuration

Edit OpenClaw config:

```bash
sudo nano /home/openclaw/.openclaw/config.yml
```

Then restart:

```bash
sudo systemctl restart openclaw
```

## Automation

### Unattended Install

```bash
# Set Tailscale auth key in playbook vars
ansible-playbook playbook-linux.yml \
  --ask-become-pass \
  -e "tailscale_authkey=tskey-auth-xxxxx"
```

### CI/CD Integration

```yaml
# Example GitHub Actions
- name: Deploy OpenClaw
  run: |
    ansible-playbook playbook-linux.yml \
      -e "tailscale_authkey=${{ secrets.TAILSCALE_KEY }}" \
      --become
```

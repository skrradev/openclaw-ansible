---
title: Troubleshooting
description: Common issues and solutions
---

# Troubleshooting

## Gateway Can't Reach Internet

**Symptom**: OpenClaw can't connect to WhatsApp/Telegram

**Check**:
```bash
# Test host connectivity
ping -c 3 8.8.8.8

# Check UFW allows outbound
sudo ufw status verbose | grep OUT
```

**Solution**:
```bash
# Verify DOCKER-USER allows established connections
sudo iptables -L DOCKER-USER -n -v

# Restart Docker + Firewall
sudo systemctl restart docker
sudo ufw reload
sudo systemctl restart openclaw
```

## Port Already in Use

**Symptom**: Port 3000 conflict

**Solution**:
```bash
# Find what's using port 3000
sudo ss -tlnp | grep 3000

# Change OpenClaw port
sudo -u openclaw nano /home/openclaw/.openclaw/config.yml
# Update gateway/listen port in config as needed

sudo systemctl restart openclaw
```

## Firewall Lockout

**Symptom**: Can't SSH after installation

**Solution** (via console/rescue mode):
```bash
# Disable UFW temporarily
sudo ufw disable

# Check SSH rule exists
sudo ufw status numbered

# Re-add SSH rule
sudo ufw allow 22/tcp

# Re-enable
sudo ufw enable
```

## Service Won't Start

**Check logs**:
```bash
# Systemd logs
sudo journalctl -u openclaw -n 50

# Service status
sudo systemctl status openclaw
```

**Common fixes**:
```bash
# Re-run playbook to reconcile packages/config
ansible-playbook playbook-linux.yml --ask-become-pass

# Check permissions
sudo chown -R openclaw:openclaw /home/openclaw/.openclaw
sudo systemctl restart openclaw
```

## Verify Docker Isolation

**Test that external ports are blocked**:
```bash
# Start test container
sudo docker run -d -p 80:80 --name test-nginx nginx

# From EXTERNAL machine (should fail):
curl http://YOUR_SERVER_IP:80

# From SERVER (should work):
curl http://localhost:80

# Cleanup
sudo docker rm -f test-nginx
```

## UFW Status Shows Inactive

**Fix**:
```bash
# Enable UFW
sudo ufw enable

# Reload rules
sudo ufw reload

# Verify
sudo ufw status verbose
```

## Ansible Playbook Fails

**Collection missing**:
```bash
ansible-galaxy collection install -r requirements.yml
```

**Permission denied**:
```bash
# Run with --ask-become-pass (Linux)
ansible-playbook playbook-linux.yml --ask-become-pass

# Or for macOS
ansible-playbook playbook-macos.yml --ask-become-pass
```

**Docker daemon not running**:
```bash
sudo systemctl start docker
# Re-run playbook
```

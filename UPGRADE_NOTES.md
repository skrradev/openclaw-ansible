# Upgrade Notes - Option A Implementation

## ✅ Completed Changes

### 1. Installation Modes (Release vs Development)
- **Files**: `roles/linux/defaults/main.yml`, `roles/macos/defaults/main.yml`
- Added `openclaw_install_mode` variable (release | development)
- Release mode: Install via `pnpm install -g openclaw@latest` (default)
- Development mode: Clone repo, build, symlink binary
- Development settings: repo URL, branch, code directory

**Files Created** (in each role):
- `roles/linux/tasks/openclaw-release.yml` - npm installation (Linux)
- `roles/linux/tasks/openclaw-development.yml` - git clone + build (Linux)
- `roles/macos/tasks/openclaw-release.yml` - npm installation (macOS)
- `roles/macos/tasks/openclaw-development.yml` - git clone + build (macOS)
- `docs/development-mode.md` - comprehensive guide

**Development Mode Features**:
- Clones to `~/code/openclaw`
- Runs `pnpm install` and `pnpm build`
- Symlinks `bin/openclaw.js` to `~/.local/bin/openclaw`
- Adds aliases: `openclaw-rebuild`, `openclaw-dev`, `openclaw-pull`
- Sets `CLAWDBOT_DEV_DIR` environment variable

**Usage**:
```bash
# Release mode (default)
./run-playbook.sh

# Development mode
./run-playbook.sh -e openclaw_install_mode=development

# With custom repo
ansible-playbook playbook-linux.yml --ask-become-pass \
  -e openclaw_install_mode=development \
  -e openclaw_repo_url=https://github.com/YOUR_USERNAME/openclaw.git \
  -e openclaw_repo_branch=feature-branch
```

### 2. OS Detection & apt update/upgrade
- **Files**: `playbook-linux.yml`, `playbook-macos.yml`
- Separate playbooks per OS (replaces single `playbook.yml` with OS detection)
- Linux playbook runs `apt update && apt upgrade` at the beginning (Debian/Ubuntu)

### 2. Homebrew Installation
- **File**: `playbook-macos.yml`
- Homebrew is installed on macOS
- macOS: `/opt/homebrew/bin/brew`
- Automatically added to PATH

### 3. OS-Specific System Tools
- **Files**:
  - `roles/linux/tasks/system-tools.yml` (apt-based)
  - `roles/macos/tasks/system-tools.yml` (brew-based)
- Each role has direct task files (no dispatcher/orchestrator pattern)
- Tools installed via appropriate package manager per OS
- Homebrew shellenv integrated into .zshrc (macOS)

### 4. OS-Specific Docker Installation
- **Files**:
  - `roles/linux/tasks/docker.yml` (Docker CE via apt)
  - `roles/macos/tasks/docker.yml` (Docker Desktop via Homebrew Cask)

### 5. OS-Specific Firewall Configuration
- **Files**:
  - `roles/linux/tasks/firewall.yml` (UFW with Docker isolation)
  - `roles/macos/tasks/firewall.yml` (Application Firewall)

### 6. DBus & systemd User Service Fixes
- **File**: `roles/linux/tasks/user.yml`
- Fixed: `loginctl enable-linger` for openclaw user
- Fixed: XDG_RUNTIME_DIR set to `/run/user/$(id -u)`
- Fixed: DBUS_SESSION_BUS_ADDRESS configuration in .bashrc
- No more manual `eval $(dbus-launch --sh-syntax)` needed!

### 7. Systemd Service Template Enhancement
- **File**: `roles/linux/templates/openclaw-host.service.j2`
- Added XDG_RUNTIME_DIR environment variable
- Added DBUS_SESSION_BUS_ADDRESS
- Added Homebrew to PATH
- Enhanced security with ProtectSystem and ProtectHome

### 8. Clawdbot Installation via pnpm
- **Files**: `roles/linux/tasks/openclaw.yml`, `roles/macos/tasks/openclaw.yml`
- Changed from `pnpm add -g` to `pnpm install -g openclaw@latest`
- Added verification step
- Added version display

### 9. Correct User Switching Command
- **File**: `run-playbook.sh`
- Changed from `sudo -i -u openclaw` to `sudo su - openclaw`
- Alternative: `sudo -u openclaw -i`
- Ensures proper login shell with .bashrc loaded

### 10. Enhanced Welcome Message
- **Files**: `playbook-linux.yml` and `playbook-macos.yml` (post_tasks)
- Recommends: `openclaw onboard --install-daemon` as first command
- Shows environment status (XDG_RUNTIME_DIR, DBUS, Homebrew)
- Provides both quick-start and manual setup paths
- More helpful command examples

### 11. Multi-OS Install Script
- **File**: `install.sh`
- Removed Debian/Ubuntu-only check
- Added OS detection for macOS and Linux
- Proper messaging for detected OS

### 12. Updated Documentation
- **File**: `README.md`
- Multi-OS badge (Debian | Ubuntu | macOS)
- Updated features list
- Added OS-specific requirements
- Added post-install instructions with `openclaw onboard --install-daemon`

## 🎯 Key Improvements

### Fixed Issues from User History
1. ✅ **DBus errors**: Automatically configured, no manual setup needed
2. ✅ **User switching**: Correct command (`sudo su - openclaw`)
3. ✅ **Environment**: XDG_RUNTIME_DIR and DBUS properly set
4. ✅ **Homebrew**: Integrated and in PATH
5. ✅ **pnpm**: Uses `pnpm install -g openclaw@latest`

### OS Detection Framework
- Clean separation between Linux and macOS tasks
- Easy to extend for other distros
- Fails gracefully with clear error messages

### Better User Experience
- Clear next steps after installation
- Recommends `openclaw onboard --install-daemon`
- Helpful welcome message with environment status
- Proper shell initialization

## 🔄 Migration Path

### For Existing Installations
If you have an existing installation, you may need to:

```bash
# 1. Update environment variables
echo 'export XDG_RUNTIME_DIR=/run/user/$(id -u)' >> ~/.bashrc

# 2. Enable lingering
sudo loginctl enable-linger openclaw

# 3. Add Homebrew to PATH (if using Linux)
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc

# 4. Reload shell
source ~/.bashrc

# 5. Reinstall openclaw
pnpm install -g openclaw@latest
```

## 📝 TODO - Future macOS Enhancements

### Items NOT Yet Implemented (for future)
- [ ] macOS-specific user creation (different from Linux)
- [ ] launchd service instead of systemd (macOS)
- [ ] Full pf firewall configuration (macOS)
- [ ] macOS-specific Tailscale configuration
- [ ] Testing on actual macOS hardware

### Current macOS Status
- ✅ Basic framework in place
- ✅ Homebrew installation works
- ✅ Docker Desktop installation configured
- ⚠️  Some tasks may need macOS testing/refinement

## 🧪 Testing Recommendations

### Linux (Debian/Ubuntu)
```bash
# Test syntax
ansible-playbook playbook-linux.yml --syntax-check

# Test full installation
./run-playbook.sh

# Verify openclaw
sudo su - openclaw
openclaw --version
openclaw onboard --install-daemon
```

### macOS (Future)
```bash
# Similar process, but may need refinements
# Recommend thorough testing before production use
```

## 🔒 Security Notes

### Enhanced systemd Security
- `ProtectSystem=strict`: Read-only system directories
- `ProtectHome=read-only`: Limited home access
- `ReadWritePaths`: Only ~/.openclaw writable
- `NoNewPrivileges`: Prevents privilege escalation

### DBus Session Security
- User-specific DBus session
- Proper XDG_RUNTIME_DIR isolation
- No root access required for daemon

## 📚 Related Files

### Modified Files
- `playbook-linux.yml` - Linux playbook (replaces `playbook.yml`)
- `playbook-macos.yml` - macOS playbook (replaces `playbook.yml`)
- `install.sh` - Multi-OS detection
- `run-playbook.sh` - Correct user switch command
- `README.md` - Multi-OS documentation

### Role Structure
- `roles/linux/` - Linux role (replaces `roles/openclaw/`)
  - `defaults/main.yml` - Linux-specific variables
  - `tasks/*.yml` - Linux task files (direct, no dispatcher pattern)
  - `templates/daemon.json.j2` - Docker daemon config
  - `templates/openclaw-host.service.j2` - Systemd service
  - `handlers/main.yml` - Docker and fail2ban restart handlers
- `roles/macos/` - macOS role (replaces `roles/openclaw/`)
  - `defaults/main.yml` - macOS-specific variables
  - `tasks/*.yml` - macOS task files (direct, no dispatcher pattern)
  - `templates/openclaw-config.yml.j2` - OpenClaw config
  - `handlers/main.yml` - macOS handlers
- `UPGRADE_NOTES.md` (this file)

---

**Implementation Date**: January 2025
**Implementation**: Option A (Incremental multi-OS support)
**Status**: ✅ Complete and ready for testing

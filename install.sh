#!/bin/bash
set -e

# Clawdbot Ansible Installer
# This script installs Ansible if needed and runs the Clawdbot playbook

# Enable 256 colors
export TERM=xterm-256color

# Force color support
if [ -z "$COLORTERM" ]; then
    export COLORTERM=truecolor
fi

REPO_URL="https://raw.githubusercontent.com/pasogott/clawdbot-ansible/main"
PLAYBOOK_URL="${REPO_URL}/playbook.yml"
TEMP_DIR=$(mktemp -d)

# Colors (with 256-color support)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Clawdbot Ansible Installer          ║${NC}"
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo ""

# Check if running on Debian/Ubuntu
if ! command -v apt-get &> /dev/null; then
    echo -e "${RED}Error: This installer only supports Debian/Ubuntu systems.${NC}"
    exit 1
fi

# Check if running as root or with sudo access
if [ "$EUID" -eq 0 ]; then
    echo -e "${GREEN}Running as root.${NC}"
    SUDO=""
    ANSIBLE_EXTRA_VARS="-e ansible_become=false"
else
    if ! command -v sudo &> /dev/null; then
        echo -e "${RED}Error: sudo is not installed. Please install sudo or run as root.${NC}"
        exit 1
    fi
    SUDO="sudo"
    ANSIBLE_EXTRA_VARS="--ask-become-pass"
fi

echo -e "${GREEN}[1/4] Checking prerequisites...${NC}"

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${YELLOW}Ansible not found. Installing...${NC}"
    $SUDO apt-get update -qq
    $SUDO apt-get install -y ansible
    echo -e "${GREEN}✓ Ansible installed${NC}"
else
    echo -e "${GREEN}✓ Ansible already installed${NC}"
fi

echo -e "${GREEN}[2/5] Downloading playbook...${NC}"

# Download the playbook and role files
cd "$TEMP_DIR"

# For simplicity, we'll clone the entire repo
echo "Cloning repository..."
git clone https://github.com/pasogott/clawdbot-ansible.git
cd clawdbot-ansible

echo -e "${GREEN}✓ Playbook downloaded${NC}"

echo -e "${GREEN}[3/5] Installing Ansible collections...${NC}"
ansible-galaxy collection install -r requirements.yml

echo -e "${GREEN}[4/5] Running Ansible playbook...${NC}"
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}You will be prompted for your sudo password.${NC}"
fi
echo ""

# Run the playbook
ansible-playbook playbook.yml $ANSIBLE_EXTRA_VARS

echo ""
echo -e "${GREEN}[5/5] Installation complete!${NC}"
echo ""

# Clawdbot ASCII Art Lobster (by jgs)
cat << 'LOBSTER'
[0;36m
    ╔═══════════════════════════════════════════════════════╗
    ║                                                       ║
    ║           [0;33m Welcome to Clawdbot! 🦞[0;36m                    ║
    ║                                                       ║
[0;31m                      ,.---._                               [0;36m║
[0;31m                  ,,,,     /       `,                       [0;36m║
[0;31m                   \\\\\\   /    '\_  ;                      [0;36m║
[0;31m                    |||| /\/``-.__\;'                       [0;36m║
[0;31m                    ::::/\/_                                [0;36m║
[0;31m    {{`-.__.-'(`(^^(^^^(^ 9 `.========='                    [0;36m║
[0;31m   {{{{{{ { ( ( (  (   (-----:=                            [0;36m║
[0;31m    {{.-'~~'-.(,(,,(,,,(__6_.'=========.                    [0;36m║
[0;31m                    ::::\/\                                 [0;36m║
[0;31m                    |||| \/\  ,-'/,                         [0;36m║
[0;31m                   ////   \ `` _/ ;                         [0;36m║
[0;31m                  ''''     \  `  .'                         [0;36m║
[0;31m                            `---'                           [0;36m║
    ║                                                       ║
    ║              [0;32m✅  Installation Successful![0;36m              ║
    ║                                                       ║
    ╚═══════════════════════════════════════════════════════╝[0m
LOBSTER
echo ""
echo -e "${GREEN}🔒 Security Status:${NC}"
echo "  - UFW Firewall: ENABLED"
echo "  - Open Ports: SSH (22) + Tailscale (41641/udp)"
echo "  - Docker isolation: ACTIVE"
echo ""
echo -e "📚 Documentation: ${GREEN}https://docs.clawd.bot${NC}"
echo ""

# Cleanup
cd /
rm -rf "$TEMP_DIR"

# Switch to clawdbot user for setup
echo -e "${YELLOW}Switching to clawdbot user for setup...${NC}"
echo ""

$SUDO su - clawdbot << 'SETUP_EOF'
echo "============================================"
echo "📋 Clawdbot Setup - Next Steps"
echo "============================================"
echo ""
echo "You are now: $(whoami)@$(hostname)"
echo "Home: $HOME"
echo ""
echo "🔧 Setup Commands:"
echo ""
echo "1. Configure Clawdbot:"
echo "   nano ~/.clawdbot/config.yml"
echo ""
echo "2. Login to provider (WhatsApp/Telegram/Signal):"
echo "   clawdbot login"
echo ""
echo "3. Test gateway:"
echo "   clawdbot gateway"
echo ""
echo "4. Exit and manage as service:"
echo "   exit"
echo "   sudo systemctl status clawdbot"
echo "   sudo journalctl -u clawdbot -f"
echo ""
echo "5. Connect Tailscale (as root):"
echo "   exit"
echo "   sudo tailscale up"
echo ""
echo "============================================"
echo ""
echo "Type 'exit' to return to previous user"
echo ""

# Start interactive bash
exec /bin/bash --login
SETUP_EOF

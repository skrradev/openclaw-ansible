#!/bin/bash
set -e

# Auto-detect OS and select the correct playbook
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLAYBOOK="playbook-macos.yml"
elif command -v apt-get &> /dev/null; then
    PLAYBOOK="playbook-linux.yml"
else
    echo "Error: Unsupported operating system."
    echo "This installer supports: Debian/Ubuntu and macOS"
    exit 1
fi

# Allow overriding playbook via first argument if it looks like a .yml file
if [[ "$1" == *.yml ]]; then
    PLAYBOOK="$1"
    shift
fi

# Run the Ansible playbook
if [ "$EUID" -eq 0 ]; then
    ansible-playbook "$PLAYBOOK" -e ansible_become=false "$@"
    PLAYBOOK_EXIT=$?
else
    ansible-playbook "$PLAYBOOK" --ask-become-pass "$@"
    PLAYBOOK_EXIT=$?
fi

# After playbook completes successfully, show instructions
if [ $PLAYBOOK_EXIT -eq 0 ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "INSTALLATION COMPLETE!"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "SWITCH TO OPENCLAW USER with:"
    echo ""
    echo "    sudo su - openclaw"
    echo ""
    echo "  OR (alternative):"
    echo ""
    echo "    sudo -u openclaw -i"
    echo ""
    echo "This will switch you to the openclaw user with a proper"
    echo "login shell (loads .bashrc, sets environment correctly)."
    echo ""
    echo "After switching, you'll see the next setup steps:"
    echo "  - Configure OpenClaw (~/.openclaw/config.yml)"
    echo "  - Login to messaging provider (WhatsApp/Telegram/Signal)"
    echo "  - Test the gateway"
    echo "  - Connect Tailscale VPN"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo ""
else
    echo "Playbook failed with exit code $PLAYBOOK_EXIT"
    exit $PLAYBOOK_EXIT
fi

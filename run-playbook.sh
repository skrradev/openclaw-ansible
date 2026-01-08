#!/bin/bash
set -e

# Run the Ansible playbook
if [ "$EUID" -eq 0 ]; then
    ansible-playbook playbook.yml -e ansible_become=false "$@"
    PLAYBOOK_EXIT=$?
else
    ansible-playbook playbook.yml --ask-become-pass "$@"
    PLAYBOOK_EXIT=$?
fi

# After playbook completes successfully, switch to clawdbot user
if [ $PLAYBOOK_EXIT -eq 0 ]; then
    # Check if we have a TTY (interactive terminal)
    if [ -t 0 ] && [ -t 1 ]; then
        echo ""
        echo "🚀 Switching to clawdbot user..."
        echo ""
        sleep 1
        
        # Execute the setup script content directly, then switch user
        /tmp/clawdbot-setup.sh
    else
        # Non-interactive - show instructions
        echo ""
        echo "✅ Installation complete!"
        echo ""
        echo "To configure Clawdbot, switch to the clawdbot user:"
        echo ""
        echo "    sudo -i -u clawdbot"
        echo ""
    fi
else
    echo "❌ Playbook failed with exit code $PLAYBOOK_EXIT"
    exit $PLAYBOOK_EXIT
fi

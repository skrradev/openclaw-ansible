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

# After playbook completes successfully, launch setup wizard
if [ $PLAYBOOK_EXIT -eq 0 ]; then
    echo ""
    echo "🚀 Launching setup wizard..."
    sleep 1
    echo ""
    
    # Check if setup script exists
    if [ -f /tmp/clawdbot-setup.sh ]; then
        exec /tmp/clawdbot-setup.sh
    else
        echo "❌ Setup script not found at /tmp/clawdbot-setup.sh"
        exit 1
    fi
else
    echo "❌ Playbook failed with exit code $PLAYBOOK_EXIT"
    exit $PLAYBOOK_EXIT
fi

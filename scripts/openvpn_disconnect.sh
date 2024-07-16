#!/bin/bash
if tmux has-session -t openvpn 2>/dev/null; then
    tmux kill-session -t openvpn
    echo "Killed active VPN connection"
else
    echo "No active VPN connections"
    exit 1
fi
exit 0
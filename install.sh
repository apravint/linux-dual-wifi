#!/usr/bin/env bash
# ==============================================================================
# Installer for linux-dual-wifi
# ==============================================================================
set -euo pipefail

INSTALL_DIR="${DESTDIR:-/usr/local/bin}"
SERVICE_DIR="/etc/systemd/system"

echo "📡 Installing linux-dual-wifi..."

if [ "$EUID" -ne 0 ]; then
    echo "Notice: Non-root user detected. Installing to ~/.local/bin and ~/.config/systemd/user"
    INSTALL_DIR="$HOME/.local/bin"
    SERVICE_DIR="$HOME/.config/systemd/user"
fi

mkdir -p "$INSTALL_DIR"
cp bin/dual-wifi "$INSTALL_DIR/dual-wifi"
chmod +x "$INSTALL_DIR/dual-wifi"
echo "✅ Installed binary to: $INSTALL_DIR/dual-wifi"

mkdir -p "$SERVICE_DIR"
sed "s|/usr/local/bin/dual-wifi|$INSTALL_DIR/dual-wifi|g" systemd/dual-wifi-keepalive.service > "$SERVICE_DIR/dual-wifi-keepalive.service"
echo "✅ Installed systemd unit to: $SERVICE_DIR/dual-wifi-keepalive.service"

echo ""
echo "To enable dual Wi-Fi load balancing on boot:"
if [ "$EUID" -eq 0 ]; then
    echo "  sudo systemctl daemon-reload"
    echo "  sudo systemctl enable --now dual-wifi-keepalive.service"
else
    echo "  systemctl --user daemon-reload"
    echo "  systemctl --user enable --now dual-wifi-keepalive.service"
fi
echo ""
echo "To test status immediately: dual-wifi status"
echo "To activate balancing:      dual-wifi balance"

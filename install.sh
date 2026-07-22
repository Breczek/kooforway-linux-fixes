#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for command in monitor-sensor gdbus systemctl; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Missing required command: $command" >&2
        exit 1
    fi
done

echo "Installing stylus calibration rule..."
sudo install -Dm644 \
    "$ROOT_DIR/udev/99-elan-stylus-calibration.rules" \
    /etc/udev/rules.d/99-elan-stylus-calibration.rules

echo "Reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger

echo "Installing autorotation script..."
install -Dm755 \
    "$ROOT_DIR/kooforway-autorotate.sh" \
    "$HOME/.local/bin/kooforway-autorotate.sh"

echo "Installing systemd user service..."
install -Dm644 \
    "$ROOT_DIR/systemd/kooforway-autorotate.service" \
    "$HOME/.config/systemd/user/kooforway-autorotate.service"

systemctl --user daemon-reload
systemctl --user enable --now kooforway-autorotate.service

echo
echo "Installation completed."
echo "Log out and log back in, or reboot the device."
echo
echo "Service status:"
systemctl --user --no-pager --full status kooforway-autorotate.service || true

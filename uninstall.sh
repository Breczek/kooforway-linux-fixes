#!/usr/bin/env bash

set -euo pipefail

echo "Stopping autorotation service..."
systemctl --user disable --now kooforway-autorotate.service 2>/dev/null || true

rm -f "$HOME/.config/systemd/user/kooforway-autorotate.service"
rm -f "$HOME/.local/bin/kooforway-autorotate.sh"

systemctl --user daemon-reload
systemctl --user reset-failed

echo "Removing stylus calibration rule..."
sudo rm -f /etc/udev/rules.d/99-elan-stylus-calibration.rules
sudo udevadm control --reload-rules
sudo udevadm trigger

echo
echo "Uninstallation completed."
echo "Log out and log back in, or reboot the device."

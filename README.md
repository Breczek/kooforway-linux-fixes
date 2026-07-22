# Kooforway Mini Laptop Linux Fixes

Linux fixes for the 8-inch Kooforway mini laptop / pocket PC equipped with an ELAN touchscreen and stylus.

This repository currently provides:

- a persistent stylus orientation fix,
- automatic screen rotation on GNOME Wayland,
- user-level `systemd` integration,
- simple install and uninstall scripts.

## Tested configuration

- Fedora Workstation 44
- GNOME
- Wayland
- built-in display: `DSI-1`
- display mode: `800x1280@60.568`
- ELAN Touchscreen Stylus:
  - vendor ID: `04f3`
  - model ID: `2f33`

The files may also work on similar devices, but the display connector, mode and sensor mapping may require adjustment.

## What was broken

### Stylus

Touch input worked correctly, but the stylus axes were rotated and the cursor was offset.

The stylus was detected as:

```text
ELAN Touchscreen Stylus
VID:PID 04f3:2f33
```

The fix applies a `libinput` calibration matrix only to the tablet/stylus device:

```text
0 1 0 -1 0 1
```

### Automatic rotation

`iio-sensor-proxy` correctly reported accelerometer orientation, but GNOME did not rotate the built-in display automatically.

The included script listens to `monitor-sensor` and applies the corresponding display transform through Mutter's `org.gnome.Mutter.DisplayConfig` D-Bus interface.

## Installation

Clone or download this repository, then run:

```bash
chmod +x install.sh uninstall.sh kooforway-autorotate.sh
./install.sh
```

Log out and log back in after installation, or reboot the device.

Check the autorotation service:

```bash
systemctl --user status kooforway-autorotate.service
```

Check whether the stylus rule was applied:

```bash
udevadm info --query=property --name=/dev/input/event9 \
  | grep LIBINPUT_CALIBRATION_MATRIX
```

The event number may differ after reboot. To locate the stylus device:

```bash
sudo libinput list-devices
```

## Manual installation

### Stylus fix

```bash
sudo cp udev/99-elan-stylus-calibration.rules \
  /etc/udev/rules.d/

sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Automatic rotation

```bash
mkdir -p ~/.local/bin ~/.config/systemd/user

cp kooforway-autorotate.sh \
  ~/.local/bin/kooforway-autorotate.sh

cp systemd/kooforway-autorotate.service \
  ~/.config/systemd/user/

chmod +x ~/.local/bin/kooforway-autorotate.sh

systemctl --user daemon-reload
systemctl --user enable --now kooforway-autorotate.service
```

## Orientation mapping

The tested device uses the following mapping:

| Accelerometer orientation | Mutter transform |
|---|---:|
| `normal` | `0` |
| `right-up` | `1` |
| `bottom-up` | `2` |
| `left-up` | `3` |

The mapping is defined near the bottom of `kooforway-autorotate.sh`.

## Configuration

The script currently assumes:

```bash
CONNECTOR="DSI-1"
MODE="800x1280@60.568"
SCALE="1.0"
```

To verify your display state:

```bash
gdbus call \
  --session \
  --dest org.gnome.Mutter.DisplayConfig \
  --object-path /org/gnome/Mutter/DisplayConfig \
  --method org.gnome.Mutter.DisplayConfig.GetCurrentState
```

Edit the variables at the top of `kooforway-autorotate.sh` if your connector or mode differs.

## Logs and troubleshooting

Follow the service logs:

```bash
journalctl --user \
  -u kooforway-autorotate.service \
  -f
```

Test the sensor directly:

```bash
monitor-sensor
```

Run the rotation script manually:

```bash
systemctl --user stop kooforway-autorotate.service
~/.local/bin/kooforway-autorotate.sh
```

Stop the test with `Ctrl+C`, then restore the service:

```bash
systemctl --user start kooforway-autorotate.service
```

### Screen does not rotate while lying flat

This is expected. When the device lies flat, the sensor may report `face-up` or `face-down`. Those states do not define a usable screen orientation, so the script keeps the current rotation.

### Stylus rule is not applied

Confirm the hardware identifiers:

```bash
udevadm info --query=property --name=/dev/input/event9 \
  | grep -E 'ID_VENDOR_ID|ID_MODEL_ID|ID_INPUT_TABLET'
```

Expected values:

```text
ID_VENDOR_ID=04f3
ID_MODEL_ID=2f33
ID_INPUT_TABLET=1
```

## Uninstallation

```bash
./uninstall.sh
```

Then log out and log back in, or reboot.

## Credits

The stylus calibration approach and the matrix used for this ELAN digitizer were discovered thanks to Patrick Bailey's article:

- https://nbailey.ca/post/p8/

This repository packages the stylus fix as a persistent `udev` rule and adds automatic screen rotation for Fedora GNOME on Wayland.

## License

MIT License. See [LICENSE](LICENSE).

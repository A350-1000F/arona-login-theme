#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR]${NC} Please run as root: sudo ./uninstall.sh"
    exit 1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Arona Login Theme Uninstaller${NC}"
echo -e "${BLUE}   阿罗娜登录主题卸载器${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. Restore default SDDM theme
print_info "Restoring default SDDM theme..."
if [ -f /etc/sddm.conf.bak.* ]; then
    NEWEST_BAK=$(ls -t /etc/sddm.conf.bak.* 2>/dev/null | head -1)
    if [ -n "$NEWEST_BAK" ]; then
        cp "$NEWEST_BAK" /etc/sddm.conf
        print_ok "Restored SDDM config from backup"
    else
        cat > /etc/sddm.conf << 'CONF'
[Theme]
Current=maldives
CONF
        print_ok "Reset to default maldives theme"
    fi
else
    cat > /etc/sddm.conf << 'CONF'
[Theme]
Current=maldives
CONF
    print_ok "Reset to default maldives theme"
fi

# 2. Remove arona theme
print_info "Removing arona SDDM theme..."
rm -rf /usr/share/sddm/themes/arona/
print_ok "SDDM theme removed"

# 3. Remove video and wallpaper
print_info "Removing assets..."
rm -f /opt/arona-wallpaper/arona-video.mp4
rmdir /opt/arona-wallpaper 2>/dev/null || true
rm -f /usr/share/backgrounds/kali/arona-wallpaper.png
print_ok "Assets removed"

# 4. Restore lockscreen XML
print_info "Restoring lock screen background..."
LOCKSCREEN_XML="/usr/share/backgrounds/kali/kali-cubes2.xml"
if [ -f "${LOCKSCREEN_XML}.bak."* ]; then
    NEWEST_BAK=$(ls -t ${LOCKSCREEN_XML}.bak.* 2>/dev/null | head -1)
    if [ -n "$NEWEST_BAK" ]; then
        cp "$NEWEST_BAK" "$LOCKSCREEN_XML"
        print_ok "Lock screen XML restored from backup"
    fi
else
    cat > "$LOCKSCREEN_XML" << 'XMLEOF'
<background>
  <static>
    <duration>8640000.0</duration>
    <file>
      <size width="3840" height="2160">/usr/share/backgrounds/kali/kali-cubes2-16x9.jpg</size>
    </file>
  </static>
</background>
XMLEOF
    print_ok "Lock screen reset to default"
fi

# 5. Remove video screensaver
print_info "Removing arona video screensaver..."
rm -f /usr/share/applications/screensavers/arona-video.desktop
print_ok "Screensaver removed"

# 6. Remove xfce4-screensaver config
print_info "Removing xfce4-screensaver config..."
REGULAR_USER=$(getent passwd 1000 | cut -d: -f1)
if [ -z "$REGULAR_USER" ]; then
    REGULAR_USER="kali"
fi
rm -f "/home/$REGULAR_USER/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-screensaver.xml"
rm -f "/home/$REGULAR_USER/.config/autostart/arona-set-wallpaper.desktop"
print_ok "xfce4-screensaver config removed"

# 7. Restore Wayland sessions
print_info "Restoring Wayland sessions..."
if [ -d /usr/share/wayland-sessions-disabled ]; then
    mkdir -p /usr/share/wayland-sessions
    mv /usr/share/wayland-sessions-disabled/*.desktop /usr/share/wayland-sessions/ 2>/dev/null || true
    rmdir /usr/share/wayland-sessions-disabled 2>/dev/null || true
    print_ok "Wayland sessions restored"
fi

# 8. Re-enable LightDM if SDDM was not the original
print_info "Restoring display manager..."
if command -v lightdm &>/dev/null; then
    systemctl enable lightdm 2>/dev/null || true
    systemctl disable sddm 2>/dev/null || true
    print_ok "LightDM re-enabled, SDDM disabled"
else
    systemctl enable sddm 2>/dev/null || true
    print_ok "SDDM kept as display manager"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Uninstall Complete!${NC}"
echo -e "${GREEN}  卸载完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Reboot recommended: sudo reboot${NC}"
echo ""

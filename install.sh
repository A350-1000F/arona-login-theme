#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TOTAL_STEPS=11
CURRENT_STEP=0

print_ok()   { echo -e "${GREEN}[完成]${NC} $1"; }
print_info() { echo -e "${BLUE}[信息]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
print_err()  { echo -e "${RED}[错误]${NC} $1"; }

step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local pct=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((pct / 5))
    local empty=$((20 - filled))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    echo ""
    echo -e "${CYAN}[$CURRENT_STEP/$TOTAL_STEPS] ${bar} ${pct}%${NC}"
    echo -e "${CYAN}>>> $1${NC}"
}

apt_progress() {
    local desc="$1"
    shift
    echo -e "  ${BLUE}正在安装: $desc...${NC}"
    local total=$(echo "$desc" | wc -w)
    local current=0
    for pkg in "$@"; do
        current=$((current + 1))
        echo -ne "\r  ${CYAN}[$current/$total] ${pkg}${NC}                    "
        DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$pkg" >/dev/null 2>&1 || true
    done
    echo ""
}

file_progress() {
    local src="$1"
    local dst="$2"
    local label="$3"
    local size=$(stat -c%s "$src" 2>/dev/null || echo 0)
    local size_mb=$((size / 1024 / 1024))
    local size_kb=$((size / 1024))

    if [ -f "$src" ]; then
        echo -ne "  ${BLUE}正在复制 ${label} (${size_mb}MB)${NC}"
        cp "$src" "$dst"
        echo -e " ${GREEN}完成${NC}"
    else
        echo -e "  ${YELLOW}${label} 源文件未找到，跳过${NC}"
    fi
}

if [[ $EUID -ne 0 ]]; then
    print_err "请以 root 权限运行: sudo ./install.sh"
    exit 1
fi

echo ""
echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   阿罗娜登录主题安装器              ║${NC}"
echo -e "${BLUE}║   Arona Login Theme Installer        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""

# --- 1. 安装依赖 ---
step "安装依赖包 (apt-get)"

echo -e "  ${BLUE}正在更新软件源列表...${NC}"
apt-get update -qq 2>&1 | while IFS= read -r line; do
    echo -ne "\r  ${CYAN}apt: ${line:0:60}${NC}"
done
echo ""

PACKAGES="sddm sddm-theme-breeze sddm-theme-maldives qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts qml6-module-qtquick-window qml6-module-qtquick-particles qml6-module-qtquick-shapes qml6-module-sddm mpv"

pkg_count=0
total_pkgs=$(echo $PACKAGES | wc -w)
for pkg in $PACKAGES; do
    pkg_count=$((pkg_count + 1))
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo -e "  ${GREEN}[$pkg_count/$total_pkgs] ✓ $pkg${NC} (已安装)"
    else
        echo -ne "  ${CYAN}[$pkg_count/$total_pkgs] ⏳ 正在安装 $pkg${NC}            \r"
        DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$pkg" >/dev/null 2>&1 || true
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            echo -e "  ${GREEN}[$pkg_count/$total_pkgs] ✓ $pkg${NC}          "
        else
            echo -e "  ${YELLOW}[$pkg_count/$total_pkgs] ⚠ $pkg (安装失败，继续)${NC}"
        fi
    fi
done

echo -e "  ${CYAN}检查可选依赖: qml6-module-qtmultimedia${NC}"
if apt-get install -y -q qml6-module-qtmultimedia >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓ qml6-module-qtmultimedia 安装成功${NC}"
else
    echo -e "  ${YELLOW}⚠ qml6-module-qtmultimedia 不可用 - 视频屏保将使用 mpv 替代${NC}"
fi

print_ok "依赖包安装完成"

# --- 2. 复制视频和壁纸 ---
step "复制资源文件 (视频 + 壁纸)"

mkdir -p /opt/arona-wallpaper

VIDEO_SRC="$SCRIPT_DIR/assets/arona-video.mp4"
VIDEO_DST="/opt/arona-wallpaper/arona-video.mp4"
if [ -f "$VIDEO_SRC" ]; then
    VIDEO_SIZE=$(stat -c%s "$VIDEO_SRC" 2>/dev/null || echo 0)
    VIDEO_MB=$((VIDEO_SIZE / 1024 / 1024))
    VIDEO_KB=$((VIDEO_SIZE / 1024))
    echo -e "  ${CYAN}源文件: arona-video.mp4 (${VIDEO_MB}MB / ${VIDEO_KB}KB)${NC}"
    echo -ne "  ${BLUE}正在复制视频到 /opt/arona-wallpaper/...${NC}"
    cp "$VIDEO_SRC" "$VIDEO_DST"
    chmod 644 "$VIDEO_DST"
    echo -e " ${GREEN}完成${NC}"
else
    echo -e "  ${RED}视频源文件未找到: $VIDEO_SRC${NC}"
fi

WALLPAPER_SRC="$SCRIPT_DIR/assets/wallpaper.png"
WALLPAPER_DST="/usr/share/backgrounds/kali/arona-wallpaper.png"
mkdir -p /usr/share/backgrounds/kali
if [ -f "$WALLPAPER_SRC" ]; then
    WP_SIZE=$(stat -c%s "$WALLPAPER_SRC" 2>/dev/null || echo 0)
    WP_MB=$((WP_SIZE / 1024 / 1024))
    echo -e "  ${CYAN}源文件: wallpaper.png (${WP_MB}MB)${NC}"
    echo -ne "  ${BLUE}正在复制壁纸到 /usr/share/backgrounds/kali/...${NC}"
    cp "$WALLPAPER_SRC" "$WALLPAPER_DST"
    chmod 644 "$WALLPAPER_DST"
    echo -e " ${GREEN}完成${NC}"
else
    echo -e "  ${RED}壁纸源文件未找到: $WALLPAPER_SRC${NC}"
fi

print_ok "资源文件复制完成"

# --- 3. 安装 SDDM 主题 ---
step "安装 SDDM 主题文件"

THEME_DIR="/usr/share/sddm/themes/arona"
mkdir -p "$THEME_DIR"

THEME_FILES="Main.qml theme.conf metadata.desktop"
for f in $THEME_FILES; do
    if [ -f "$SCRIPT_DIR/themes/arona/$f" ]; then
        echo -e "  ${GREEN}✓ $f${NC}"
        cp "$SCRIPT_DIR/themes/arona/$f" "$THEME_DIR/"
    fi
done

if [ -f "$SCRIPT_DIR/themes/arona/preview.jpg" ]; then
    echo -e "  ${GREEN}✓ preview.jpg${NC}"
    cp "$SCRIPT_DIR/themes/arona/preview.jpg" "$THEME_DIR/"
fi

chmod -R 755 "$THEME_DIR"
print_ok "SDDM 主题已安装到 $THEME_DIR"

# --- 4. 配置 SDDM ---
step "配置 SDDM (/etc/sddm.conf)"

if [ -f /etc/sddm.conf ]; then
    cp /etc/sddm.conf "/etc/sddm.conf.bak.$(date +%s)"
    echo -e "  ${YELLOW}⚠ 已备份原有 /etc/sddm.conf${NC}"
fi

echo -e "  ${CYAN}正在写入 /etc/sddm.conf...${NC}"
cat > /etc/sddm.conf << 'CONF'
[Theme]
Current=arona
CursorTheme=default
EnableAvatars=true

[Users]
MaximumUid=60534
MinimumUid=1000

[Wayland]
EnableWayland=false

[Display]
DisplayServer=x11
InputMethod=none
SessionDir=/usr/share/xsessions
CONF
print_ok "SDDM 配置完成 (主题=arona, X11, 禁用虚拟键盘)"

# --- 5. 切换显示管理器 ---
step "切换显示管理器 (LightDM → SDDM)"

if command -v lightdm &>/dev/null; then
    echo -ne "  ${BLUE}正在禁用 LightDM...${NC}"
    systemctl disable lightdm 2>/dev/null || true
    echo -e " ${GREEN}完成${NC}"
else
    echo -e "  ${CYAN}LightDM 未安装，跳过${NC}"
fi

echo -ne "  ${BLUE}正在启用 SDDM...${NC}"
systemctl enable sddm 2>/dev/null || true
echo -e " ${GREEN}完成${NC}"
print_ok "SDDM 已设为开机自启"

# --- 6. 配置 sddm 用户权限 ---
step "配置 sddm 用户权限"

for grp in video render audio; do
    echo -ne "  ${BLUE}将 sddm 加入 ${grp} 组...${NC}"
    usermod -a -G "$grp" sddm 2>/dev/null || true
    echo -e " ${GREEN}完成${NC}"
done
print_ok "sddm 用户已加入 video + render + audio 组"

# --- 7. 禁用 Wayland 会话 ---
step "禁用 Wayland 会话 (VMware 兼容)"

if [ -d /usr/share/wayland-sessions ]; then
    mkdir -p /usr/share/wayland-sessions-disabled
    session_count=0
    for f in /usr/share/wayland-sessions/*.desktop; do
        if [ -f "$f" ]; then
            session_count=$((session_count + 1))
            echo -e "  ${CYAN}移动: $(basename "$f")${NC}"
            mv "$f" /usr/share/wayland-sessions-disabled/ 2>/dev/null || true
        fi
    done
    echo -e "  ${YELLOW}已移动 $session_count 个 Wayland 会话${NC}"
else
    echo -e "  ${CYAN}未找到 Wayland 会话目录${NC}"
fi
print_ok "Wayland 已禁用"

# --- 8. 配置锁屏背景 ---
step "配置锁屏背景壁纸"

LOCKSCREEN_XML="/usr/share/backgrounds/kali/kali-cubes2.xml"
if [ -f "$LOCKSCREEN_XML" ]; then
    cp "$LOCKSCREEN_XML" "${LOCKSCREEN_XML}.bak.$(date +%s)"
    echo -e "  ${CYAN}已备份原始锁屏 XML${NC}"
fi

echo -e "  ${CYAN}设置锁屏壁纸 → arona-wallpaper.png${NC}"
cat > "$LOCKSCREEN_XML" << 'XMLEOF'
<background>
  <static>
    <duration>8640000.0</duration>
    <file>
      <size width="3840" height="2160">/usr/share/backgrounds/kali/arona-wallpaper.png</size>
    </file>
  </static>
</background>
XMLEOF
print_ok "锁屏背景已设置"

# --- 9. 创建视频屏保 ---
step "创建阿罗娜视频屏保"

SS_DIR="/usr/share/applications/screensavers"
mkdir -p "$SS_DIR"

cat > "$SS_DIR/arona-video.desktop" << 'DESKTOPEOF'
[Desktop Entry]
Type=Application
Name=Arona Video
Name[zh_CN]=阿罗娜摸鱼视频
Comment=Plays Arona video as screensaver
Comment[zh_CN]=播放阿罗娜摸鱼视频
Exec=mpv --loop --no-audio --fullscreen --osdlevel=0 /opt/arona-wallpaper/arona-video.mp4
TryExec=mpv
Icon=video-display
Categories=Screensaver
DESKTOPEOF
chmod 644 "$SS_DIR/arona-video.desktop"
echo -e "  ${GREEN}✓ 已创建: $SS_DIR/arona-video.desktop${NC}"
print_ok "视频屏保创建完成"

# --- 10. 配置 xfce4-screensaver ---
step "配置 xfce4-screensaver 屏保设置"

REGULAR_USER=$(getent passwd 1000 | cut -d: -f1)
if [ -z "$REGULAR_USER" ]; then
    REGULAR_USER="kali"
fi
echo -e "  ${CYAN}目标用户: $REGULAR_USER${NC}"

USER_CONFIG_DIR="/home/$REGULAR_USER/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$USER_CONFIG_DIR"

echo -e "  ${CYAN}正在写入 xfce4-screensaver.xml...${NC}"
cat > "$USER_CONFIG_DIR/xfce4-screensaver.xml" << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-screensaver">
  <property name="saver" type="empty">
    <property name="enabled" type="bool" value="true"/>
    <property name="mode" type="int" value="2"/>
    <property name="enabled_savers" type="string" value="arona-video"/>
    <property name="timeout" type="int" value="10"/>
  </property>
  <property name="lock" type="empty">
    <property name="enabled" type="bool" value="true"/>
    <property name="saver" type="bool" value="true"/>
  </property>
</channel>
XMLEOF
chown -R "$REGULAR_USER":"$REGULAR_USER" "$USER_CONFIG_DIR"
print_ok "xfce4-screensaver 已配置 (超时=10秒, 锁屏=开启, 屏保=arona-video)"

# --- 11. 设置 gsettings ---
step "设置 gsettings 锁屏参数"

if [ -f "/run/user/1000/bus" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"
    echo -ne "  ${BLUE}设置 picture-uri...${NC}"
    sudo -u "$REGULAR_USER" dbus-launch dconf write /org/gnome/desktop/screensaver/picture-uri \
        "'file:///usr/share/backgrounds/kali/arona-wallpaper.png'" 2>/dev/null || true
    echo -e " ${GREEN}完成${NC}"
    echo -ne "  ${BLUE}设置 picture-options=zoom...${NC}"
    sudo -u "$REGULAR_USER" dbus-launch dconf write /org/gnome/desktop/screensaver/picture-options \
        "'zoom'" 2>/dev/null || true
    echo -e " ${GREEN}完成${NC}"
    print_ok "gsettings 已更新"
else
    echo -e "  ${YELLOW}⚠ D-Bus 会话不可用${NC}"
    echo -e "  ${CYAN}创建自启动脚本，下次登录时自动设置...${NC}"
    mkdir -p "/home/$REGULAR_USER/.config/autostart"
    cat > "/home/$REGULAR_USER/.config/autostart/arona-set-wallpaper.desktop" << 'AUTOSTARTEOF'
[Desktop Entry]
Type=Application
Name=Arona Wallpaper Setter
Exec=sh -c 'gsettings set org.gnome.desktop.screensaver picture-uri "file:///usr/share/backgrounds/kali/arona-wallpaper.png" && gsettings set org.gnome.desktop.screensaver picture-options "zoom" && rm -f ~/.config/autostart/arona-set-wallpaper.desktop'
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
AUTOSTARTEOF
    chown "$REGULAR_USER":"$REGULAR_USER" "/home/$REGULAR_USER/.config/autostart/arona-set-wallpaper.desktop"
    print_ok "自启动脚本已创建 (下次登录时自动设置 gsettings)"
fi

# --- 完成 ---
echo ""
echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✓ 安装完成！                       ║${NC}"
echo -e "${GREEN}║  ✓ Installation Complete!           ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}已安装组件:${NC}"
echo "  SDDM 主题:           /usr/share/sddm/themes/arona/"
echo "  视频壁纸:             /opt/arona-wallpaper/arona-video.mp4"
echo "  静态壁纸:             /usr/share/backgrounds/kali/arona-wallpaper.png"
echo "  锁屏背景:             kali-cubes2.xml → arona-wallpaper.png"
echo "  视频屏保:             arona-video.desktop (mpv 播放)"
echo "  xfce4-screensaver:   超时=10秒, 锁屏=开启"
echo ""
echo -e "${YELLOW}后续操作:${NC}"
echo "  1. 重启 SDDM:        sudo systemctl restart sddm"
echo "  2. 或直接重启:       sudo reboot"
echo "  3. 测试锁屏:         xfce4-screensaver-command --lock"
echo ""
echo -e "${YELLOW}卸载:${NC}"
echo "  sudo ./uninstall.sh"
echo ""

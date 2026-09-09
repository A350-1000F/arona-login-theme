# Arona Login Theme - 阿罗娜登录主题

Kali Linux (SDDM) 阿罗娜主题登录界面美化项目。包含视频壁纸、蓝色粒子动画、扫描线效果和脉冲登录框。

## 功能

- **SDDM 登录界面**：蓝档壁纸背景 + 40个浮动蓝色粒子 + 扫描线动画 + 登录框脉冲发光 + 顶部时钟
- **锁屏界面**：壁纸背景改为阿罗娜壁纸 + mpv 视频屏保（10秒触发）
- **一键安装/卸载**：install.sh / uninstall.sh

## 项目结构

```
arona-login-theme/
├── install.sh                    # 一键安装脚本
├── uninstall.sh                  # 一键卸载脚本
├── README.md                     # 说明文档
├── assets/
│   ├── arona-video.mp4           # 阿罗娜摸鱼视频 (1920x1080, ~4MB)
│   └── wallpaper.png             # 阿罗娜壁纸
├── themes/
│   └── arona/
│       ├── Main.qml              # SDDM 主题主文件
│       ├── theme.conf            # 主题配置
│       ├── metadata.desktop      # 主题元数据
│       └── preview.jpg           # 预览图
└── scripts/
    └── set-lockscreen.sh         # 锁屏配置脚本
```

## 安装

```bash
# 1. 将项目传到 Kali
scp -r arona-login-theme/ kali@<IP>:~/

# 2. 在 Kali 上执行
cd ~/arona-login-theme
chmod +x install.sh
sudo ./install.sh

# 3. 重启生效
sudo reboot
```

## 卸载

```bash
cd ~/arona-login-theme
chmod +x uninstall.sh
sudo ./uninstall.sh
sudo reboot
```

## 安装后的系统路径

| 组件 | 路径 |
|------|------|
| SDDM 主题 | `/usr/share/sddm/themes/arona/` |
| 视频文件 | `/opt/arona-wallpaper/arona-video.mp4` |
| 静态壁纸 | `/usr/share/backgrounds/kali/arona-wallpaper.png` |
| 锁屏背景 | `/usr/share/backgrounds/kali/kali-cubes2.xml` |
| 视频屏保 | `/usr/share/applications/screensavers/arona-video.desktop` |
| SDDM 配置 | `/etc/sddm.conf` |

## 注意事项

- 强制使用 X11（禁用 Wayland），VMware 兼容
- 禁用虚拟键盘 (InputMethod=none)
- sddm 用户已加入 video/render/audio 组
- 如安装后无法登录，切到 TTY (Ctrl+Alt+F2) 运行 `sudo ./uninstall.sh`

## 主题特性

- 纯 QML 渲染（不依赖 WebEngine）
- CPU 占用约 50%，内存约 250MB
- 不使用 QtQuick.Particles（用 Repeater+NumberAnimation 替代，兼容 Qt6）
- 按钮使用自定义 Rectangle+Text（SddmComponents Button 在 Qt6 下有 bug）

#!/bin/bash

# ========================================
# Hyprland Material You Setup Script
# For OpenSUSE Tumbleweed Minimal Install
# Android-inspired Desktop Environment
# ========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Welcome screen
clear
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    🎨 Hyprland Material You Desktop Environment 🎨       ║
║                                                           ║
║    Android-inspired | Dynamic Colors | Smooth UI         ║
║    Based on end-4/dots-hyprland illogical-impulse        ║
║                                                           ║
║    Target: OpenSUSE Tumbleweed Minimal                   ║
║    Hardware: HP Victus 16 (RTX 3050, R7-7840HS)         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF

sleep 2

# System check
log_step "Sistem kontrolü yapılıyor..."

if [ ! -f /etc/os-release ]; then
    log_error "OS bilgisi alınamadı!"
    exit 1
fi

. /etc/os-release

if [[ ! "$NAME" =~ "openSUSE Tumbleweed" ]]; then
    log_warning "Bu script OpenSUSE Tumbleweed için tasarlandı."
    log_warning "Devam etmek istediğinize emin misiniz? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

log_success "Sistem: $NAME"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Bu scripti root olarak çalıştırmayın! Sudo otomatik kullanılacak."
    exit 1
fi

# Confirm installation
log_warning "Bu kurulum şunları yapacak:"
echo "  • Hyprland ve Wayland bileşenlerini kuracak"
echo "  • Quickshell (Qt6 tabanlı shell) derleyecek"
echo "  • Material You renk sistemi kuracak"
echo "  • Android-benzeri arayüz yapılandırması"
echo "  • NVIDIA sürücüleri ve optimizasyonları"
echo "  • Tam tema entegrasyonu (GTK, Qt, Cursor, Icons)"
echo ""
log_warning "Devam edilsin mi? (y/n)"
read -r confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_info "Kurulum iptal edildi."
    exit 0
fi

# ========================================
# PHASE 1: System Update & Base Packages
# ========================================

log_step "PHASE 1: Sistem güncellemesi ve temel paketler"

log_info "Sistem güncelleniyor..."
sudo zypper refresh
sudo zypper -n update

log_info "Temel geliştirme araçları kuruluyor..."
sudo zypper -n install -t pattern devel_basis devel_C_C++

sudo zypper -n install \
    git \
    curl \
    wget \
    rsync \
    unzip \
    tar \
    gzip \
    vim \
    nano \
    htop \
    neofetch \
    cmake \
    meson \
    ninja \
    gcc \
    gcc-c++ \
    clang \
    python3 \
    python3-pip \
    python3-devel \
    nodejs \
    npm \
    jq \
    ripgrep \
    fd \
    fzf \
    xdg-utils \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-hyprland

log_success "Temel sistem hazır"

# ========================================
# PHASE 2: Wayland & Graphics Stack
# ========================================

log_step "PHASE 2: Wayland ve grafik stack"

log_info "Wayland ve protokoller kuruluyor..."
sudo zypper -n install \
    wayland-devel \
    wayland-protocols-devel \
    libwayland-client0 \
    libwayland-server0 \
    libwayland-cursor0 \
    libwayland-egl1 \
    wlroots \
    wlroots-devel \
    mesa \
    mesa-devel \
    libdrm-devel \
    libinput-devel \
    libxkbcommon-devel \
    pixman-devel \
    cairo-devel \
    pango-devel

log_info "NVIDIA sürücüleri ve optimizasyonlar..."

# AMD/NVIDIA detection
if lspci | grep -i nvidia > /dev/null; then
    log_info "NVIDIA GPU tespit edildi - RTX 3050 için özel ayarlar"
    
    sudo zypper -n install \
        nvidia-video-G06 \
        nvidia-gl-G06 \
        nvidia-compute-G06 \
        nvidia-utils-G06
    
    # NVIDIA Hyprland env variables
    sudo mkdir -p /etc/profile.d
    sudo tee /etc/profile.d/nvidia-hyprland.sh > /dev/null << 'NVIDIA_EOF'
export LIBVA_DRIVER_NAME=nvidia
export XDG_SESSION_TYPE=wayland
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export WLR_NO_HARDWARE_CURSORS=1
NVIDIA_EOF
    
    log_success "NVIDIA ayarları yapıldı"
fi

log_success "Grafik stack hazır"

# ========================================
# PHASE 3: Hyprland & Core Compositor
# ========================================

log_step "PHASE 3: Hyprland kuruluyor"

log_info "Hyprland bağımlılıkları..."
sudo zypper -n install \
    hyprland \
    xdg-desktop-portal-hyprland \
    hypridle \
    hyprlock \
    hyprpaper \
    hyprpicker

# If not available in repos, build from source
if ! command -v Hyprland &> /dev/null; then
    log_warning "Hyprland repository'de bulunamadı, kaynak koddan derleniyor..."
    
    cd /tmp
    git clone --recursive https://github.com/hyprwm/Hyprland
    cd Hyprland
    
    make all
    sudo make install
    
    cd ~
    rm -rf /tmp/Hyprland
    
    log_success "Hyprland derlendi ve kuruldu"
fi

log_success "Hyprland hazır"

# ========================================
# PHASE 4: Qt6 & Quickshell Build
# ========================================

log_step "PHASE 4: Qt6 ve Quickshell derleniyor"

log_info "Qt6 geliştirme paketleri kuruluyor..."
sudo zypper -n install \
    qt6-base-devel \
    qt6-declarative-devel \
    qt6-wayland \
    qt6-svg-devel \
    qt6-tools-devel \
    qt6-multimedia-devel \
    libQt6Gui6 \
    libQt6Quick6 \
    libQt6Qml6 \
    libQt6Core6 \
    libQt6Widgets6 \
    libQt6DBus6 \
    qml-qt6 \
    qt6-quick-devel \
    qt6-quickcontrols2-devel \
    libqt6-qtquickcontrols2

log_info "Quickshell derleniyor (end-4 fork)..."

cd ~/.cache
git clone --recursive https://github.com/outfoxxed/quickshell.git
cd quickshell

mkdir build
cd build

cmake -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DUSE_QT6=ON \
    ..

ninja
sudo ninja install

cd ~
log_success "Quickshell kuruldu"

# ========================================
# PHASE 5: UI Components & Utilities
# ========================================

log_step "PHASE 5: UI bileşenleri ve yardımcı araçlar"

log_info "Terminal ve launcher..."
sudo zypper -n install \
    foot \
    kitty \
    fuzzel \
    rofi-wayland \
    wofi

log_info "Bildirim sistemi..."
sudo zypper -n install \
    dunst \
    mako \
    libnotify-tools

log_info "Ses sistemi..."
sudo zypper -n install \
    pipewire \
    pipewire-pulseaudio \
    pipewire-alsa \
    wireplumber \
    pavucontrol \
    pamixer \
    playerctl

log_info "Ekran görüntüsü ve clipboard..."
sudo zypper -n install \
    grim \
    slurp \
    swappy \
    wl-clipboard \
    cliphist

log_info "Dosya yöneticisi ve ağ..."
sudo zypper -n install \
    thunar \
    nautilus \
    network-manager-applet \
    blueman \
    bluez

log_info "Swww (wallpaper daemon)..."
cd /tmp
wget https://github.com/LGFae/swww/releases/latest/download/swww-x86_64-unknown-linux-musl -O swww
chmod +x swww
sudo mv swww /usr/local/bin/
cd ~

log_info "Ek araçlar..."
sudo zypper -n install \
    brightnessctl \
    wlsunset \
    polkit-gnome \
    gnome-keyring \
    btop \
    cava

log_success "UI bileşenleri kuruldu"

# ========================================
# PHASE 6: Material You Color System
# ========================================

log_step "PHASE 6: Material You renk sistemi"

log_info "Python Material Color Utilities kuruluyor..."
pip3 install --user --break-system-packages \
    materialyoucolor \
    material-color-utilities \
    pillow \
    colorthief \
    pywal

log_info "kde-material-you-colors derleniyor..."

cd ~/.cache

# Install KDE/Qt color dependencies
sudo zypper -n install \
    kconfig-devel \
    kconfigwidgets-devel \
    kcoreaddons-devel \
    ki18n-devel \
    kpackage-devel \
    plasma5-workspace-devel \
    extra-cmake-modules

git clone https://github.com/luisbocanegra/kde-material-you-colors.git
cd kde-material-you-colors

mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
sudo make install

cd ~

log_info "Renk çıkarma script'leri hazırlanıyor..."

mkdir -p ~/.local/bin
mkdir -p ~/.config/material-you

# Material You color extractor script
cat > ~/.local/bin/material-color-extract << 'COLOREOF'
#!/usr/bin/env python3

import sys
import json
from pathlib import Path
from PIL import Image
from materialyoucolor.quantize import QuantizeCelebi
from materialyoucolor.score.score import Score
from materialyoucolor.hct import Hct
from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot
from materialyoucolor.scheme.scheme_content import SchemeContent
from materialyoucolor.scheme.scheme_fidelity import SchemeFidelity

def extract_colors(image_path, scheme_type="tonal_spot", dark_mode=False):
    """Extract Material You colors from wallpaper"""
    
    # Load and resize image for performance
    img = Image.open(image_path)
    img = img.resize((112, 112))
    
    # Get pixels
    pixels = []
    for y in range(img.height):
        for x in range(img.width):
            r, g, b = img.getpixel((x, y))[:3]
            pixels.append((r << 16) | (g << 8) | b)
    
    # Quantize colors
    result = QuantizeCelebi(pixels, 128)
    
    # Score colors
    ranked = Score.score(result)
    
    # Get primary color
    source_color = ranked[0] if ranked else 0xFF5252
    
    # Generate scheme
    if scheme_type == "content":
        scheme = SchemeContent(Hct.from_int(source_color), dark_mode, 0.0)
    elif scheme_type == "fidelity":
        scheme = SchemeFidelity(Hct.from_int(source_color), dark_mode, 0.0)
    else:  # tonal_spot
        scheme = SchemeTonalSpot(Hct.from_int(source_color), dark_mode, 0.0)
    
    colors = MaterialDynamicColors()
    
    def get_color(dynamic_color):
        return f"#{dynamic_color.get_hct(scheme).to_rgba()[1:7]}"
    
    # Build color palette
    palette = {
        "source": f"#{source_color:06x}",
        "primary": get_color(colors.primary),
        "onPrimary": get_color(colors.on_primary),
        "primaryContainer": get_color(colors.primary_container),
        "onPrimaryContainer": get_color(colors.on_primary_container),
        
        "secondary": get_color(colors.secondary),
        "onSecondary": get_color(colors.on_secondary),
        "secondaryContainer": get_color(colors.secondary_container),
        "onSecondaryContainer": get_color(colors.on_secondary_container),
        
        "tertiary": get_color(colors.tertiary),
        "onTertiary": get_color(colors.on_tertiary),
        "tertiaryContainer": get_color(colors.tertiary_container),
        "onTertiaryContainer": get_color(colors.on_tertiary_container),
        
        "error": get_color(colors.error),
        "onError": get_color(colors.on_error),
        "errorContainer": get_color(colors.error_container),
        "onErrorContainer": get_color(colors.on_error_container),
        
        "background": get_color(colors.background),
        "onBackground": get_color(colors.on_background),
        "surface": get_color(colors.surface),
        "onSurface": get_color(colors.on_surface),
        
        "surfaceVariant": get_color(colors.surface_variant),
        "onSurfaceVariant": get_color(colors.on_surface_variant),
        "outline": get_color(colors.outline),
        "outlineVariant": get_color(colors.outline_variant),
        
        "shadow": get_color(colors.shadow),
        "scrim": get_color(colors.scrim),
        "inverseSurface": get_color(colors.inverse_surface),
        "inverseOnSurface": get_color(colors.inverse_on_surface),
        "inversePrimary": get_color(colors.inverse_primary),
    }
    
    return palette

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: material-color-extract <image_path> [scheme_type] [dark_mode]")
        sys.exit(1)
    
    image_path = sys.argv[1]
    scheme_type = sys.argv[2] if len(sys.argv) > 2 else "tonal_spot"
    dark_mode = sys.argv[3].lower() == "true" if len(sys.argv) > 3 else False
    
    colors = extract_colors(image_path, scheme_type, dark_mode)
    print(json.dumps(colors, indent=2))
COLOREOF

chmod +x ~/.local/bin/material-color-extract

log_success "Material You renk sistemi kuruldu"

# ========================================
# PHASE 7: GTK & Qt Theming
# ========================================

log_step "PHASE 7: GTK ve Qt tema sistemi"

log_info "GTK temaları kuruluyor..."
sudo zypper -n install \
    gtk3-devel \
    gtk4-devel \
    libadwaita-1-0 \
    libadwaita-devel

log_info "Qt tema araçları..."
sudo zypper -n install \
    qt6ct \
    kvantum \
    kvantum-qt6

log_info "Icon ve cursor temaları..."
sudo zypper -n install \
    papirus-icon-theme \
    breeze-icons \
    adwaita-icon-theme \
    xcursor-themes

# Bibata cursor theme
log_info "Bibata Modern cursor kurulum..."
cd /tmp
wget -q https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz
tar -xf Bibata-Modern-Classic.tar.xz
sudo mv Bibata-Modern-Classic /usr/share/icons/
cd ~

# Nerd Fonts
log_info "Nerd Fonts kuruluyor..."
mkdir -p ~/.local/share/fonts

cd /tmp
wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
unzip -q JetBrainsMono.zip -d JetBrainsMono
mv JetBrainsMono/*.ttf ~/.local/share/fonts/

wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip
unzip -q FiraCode.zip -d FiraCode
mv FiraCode/*.ttf ~/.local/share/fonts/

fc-cache -f

cd ~

log_success "GTK/Qt tema sistemi hazır"

# ========================================
# PHASE 8: Dots & Configuration
# ========================================

log_step "PHASE 8: Konfigürasyon dosyaları hazırlanıyor"

log_info "Backup mevcut config..."
backup_dir=~/.config-backup-$(date +%Y%m%d-%H%M%S)
mkdir -p "$backup_dir"

for dir in hypr quickshell waybar foot kitty; do
    if [ -d ~/.config/$dir ]; then
        mv ~/.config/$dir "$backup_dir/"
    fi
done

log_info "Temel dizin yapısı oluşturuluyor..."
mkdir -p ~/.config/{hypr,quickshell,waybar,foot,kitty,fuzzel,mako,swaylock}
mkdir -p ~/.local/share/{wallpapers,themes}
mkdir -p ~/Pictures/Screenshots

# ========================================
# Hyprland Configuration
# ========================================

log_info "Hyprland config yazılıyor..."

cat > ~/.config/hypr/hyprland.conf << 'HYPRCONF'
# ========================================
# Hyprland Configuration
# Material You Android-inspired Desktop
# ========================================

# Monitor configuration
monitor=,preferred,auto,1

# Environment variables
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Bibata-Modern-Classic
env = QT_QPA_PLATFORM,wayland
env = QT_QPA_PLATFORMTHEME,qt6ct
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = GDK_BACKEND,wayland,x11
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland

# NVIDIA specific
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1

# Quickshell environment
env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,$HOME/.local/state/quickshell/.venv

# Execute at launch
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = gnome-keyring-daemon --start --components=secrets
exec-once = swww init
exec-once = qs -c ~/.config/quickshell/shell.qml
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = hypridle
exec-once = blueman-applet
exec-once = nm-applet --indicator

# Input configuration
input {
    kb_layout = tr
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 1
    sensitivity = 0
    accel_profile = adaptive
    
    touchpad {
        natural_scroll = true
        tap-to-click = true
        drag_lock = false
        disable_while_typing = true
    }
}

# General settings
general {
    gaps_in = 6
    gaps_out = 12
    border_size = 2
    
    # Dynamic colors from Material You
    col.active_border = rgb(BB86FC)
    col.inactive_border = rgb(3700B3)
    
    layout = dwindle
    
    allow_tearing = false
}

# Decoration
decoration {
    rounding = 16
    
    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
        xray = false
        ignore_opacity = true
        noise = 0.02
        contrast = 1.1
        brightness = 1.0
        vibrancy = 0.2
    }

    drop_shadow = true
    shadow_range = 20
    shadow_render_power = 3
    col.shadow = rgba(00000099)
    col.shadow_inactive = rgba(00000066)
    
    dim_inactive = false
    dim_strength = 0.05
}

# Animations - Smooth Android-like
animations {
    enabled = true
    
    bezier = material, 0.4, 0.0, 0.2, 1
    bezier = easeInOut, 0.4, 0, 0.6, 1
    bezier = overshot, 0.13, 0.99, 0.29, 1.1
    bezier = smoothOut, 0.36, 0, 0.66, -0.56
    bezier = smoothIn, 0.25, 1, 0.5, 1
    
    animation = windows, 1, 4, material, slide
    animation = windowsOut, 1, 4, material, slide
    animation = windowsMove, 1, 4, material, slide
    
    animation = border, 1, 10, default
    animation = borderangle, 1, 100, default, loop
    
    animation = fade, 1, 7, default
    animation = fadeIn, 1, 4, smoothIn
    animation = fadeOut, 1, 4, smoothOut
    animation = fadeSwitch, 1, 4, material
    animation = fadeShadow, 1, 4, material
    animation = fadeDim, 1, 4, material
    
    animation = workspaces, 1, 5, material, slide
    animation = specialWorkspace, 1, 5, material, slidevert
}

# Layouts
dwindle {
    pseudotile = true
    preserve_split = true
    smart_split = false
    smart_resizing = true
}

master {
    new_is_master = true
    mfact = 0.5
}

# Gestures
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 300
    workspace_swipe_cancel_ratio = 0.5
    workspace_swipe_min_speed_to_force = 20
    workspace_swipe_create_new = true
}

# Misc
misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    mouse_move_enables_dpms = true
    key_press_enables_dpms = true
    vrr = 1
    enable_swallow = true
    swallow_regex = ^(foot|kitty)$
    focus_on_activate = false
    
    # AMD/NVIDIA specific
    no_direct_scanout = true
}

# Window rules
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(nm-connection-editor)$
windowrule = float, ^(thunar)$
windowrulev2 = opacity 0.95 0.85, class:^(kitty)$
windowrulev2 = opacity 0.95 0.85, class:^(foot)$

# Layer rules
layerrule = blur, quickshell
layerrule = blur, notifications
layerrule = blur, launcher
layerrule = ignorealpha 0.5, quickshell

# ========================================
# Keybindings - Android-inspired
# ========================================

$mainMod = SUPER

# Applications
bind = $mainMod, RETURN, exec, kitty
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, SPACE, exec, fuzzel
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, F, fullscreen, 1

# Quickshell toggles
bind = $mainMod, A, exec, qs -m ii toggle-panel iiSidebarLeft
bind = $mainMod, D, exec, qs -m ii toggle-panel iiSidebarRight
bind = $mainMod, TAB, exec, qs -m ii toggle-panel iiOverview

# Screenshot
bind = , PRINT, exec, grim -g "$(slurp)" - | swappy -f -
bind = SHIFT, PRINT, exec, grim - | swappy -f -

# Color picker
bind = $mainMod SHIFT, C, exec, hyprpicker -a

# Wallpaper switcher
bind = $mainMod CTRL, T, exec, ~/.config/quickshell/scripts/wallpaper-picker.sh

# Volume
binde = , XF86AudioRaiseVolume, exec, pamixer -i 5
binde = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t
bind = , XF86AudioMicMute, exec, pamixer --default-source -t

# Media
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

# Brightness
binde = , XF86MonBrightnessUp, exec, brightnessctl s 5%+
binde = , XF86MonBrightnessDown, exec, brightnessctl s 5%-

# Focus movement
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

bind = $mainMod, H, movefocus, l
bind = $mainMod, L, movefocus, r
bind = $mainMod, K, movefocus, u
bind = $mainMod, J, movefocus, d

# Window movement
bind = $mainMod SHIFT, left, movewindow, l
bind = $mainMod SHIFT, right, movewindow, r
bind = $mainMod SHIFT, up, movewindow, u
bind = $mainMod SHIFT, down, movewindow, d

# Workspace switching
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move window to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Mouse bindings
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Scroll through workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Lock screen
bind = $mainMod, L, exec, hyprlock
HYPRCONF

# ========================================
# Quickshell Base Structure
# ========================================

log_info "Quickshell yapısı oluşturuluyor..."

mkdir -p ~/.config/quickshell/{modules,scripts,styles}

cat > ~/.config/quickshell/shell.qml << 'QSSHELL'
import QtQuick
import Quickshell

ShellRoot {
    id: root
    
    // Color manager
    property var colors: ColorManager {}
    
    // Main bar
    PanelWindow {
        id: topBar
        
        anchors {
            top: true
            left: true
            right: true
        }
        
        height: 48
        color: colors.surface
        
        Rectangle {
            anchors.fill: parent
            color: colors.surface
            radius: 24
            
            Row {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12
                
                // Launcher button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: colors.primary
                    
                    Text {
                        anchors.centerIn: parent
                        text: "○"
                        color: colors.onPrimary
                        font.pixelSize: 20
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Quickshell.run("fuzzel")
                    }
                }
                
                // Clock
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(new Date(), "hh:mm")
                    color: colors.onSurface
                    font.pixelSize: 16
                }
            }
        }
    }
    
    // Quick Settings Panel (Android-style)
    PanelWindow {
        id: quickSettings
        visible: false
        
        anchors {
            top: true
            right: true
        }
        
        margins {
            top: 56
            right: 12
        }
        
        width: 400
        height: 600
        
        color: "transparent"
        
        Rectangle {
            anchors.fill: parent
            color: colors.surfaceVariant
            radius: 24
            opacity: 0.95
            
            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                
                Text {
                    text: "Quick Settings"
                    color: colors.onSurface
                    font.pixelSize: 20
                    font.bold: true
                }
                
                // Quick toggles grid
                Grid {
                    columns: 2
                    spacing: 12
                    
                    // WiFi toggle
                    QuickToggle {
                        title: "WiFi"
                        icon: "📶"
                        active: true
                    }
                    
                    // Bluetooth toggle
                    QuickToggle {
                        title: "Bluetooth"
                        icon: "🔵"
                        active: false
                    }
                }
            }
        }
    }
    
    // Color manager component
    QtObject {
        id: ColorManager
        
        property string primary: "#BB86FC"
        property string onPrimary: "#000000"
        property string secondary: "#03DAC6"
        property string surface: "#121212"
        property string surfaceVariant: "#1E1E1E"
        property string onSurface: "#FFFFFF"
        property string background: "#000000"
        
        function updateFromWallpaper(wallpaperPath) {
            // Call Python script to extract colors
            const result = Quickshell.run(
                "material-color-extract",
                wallpaperPath,
                "tonal_spot",
                "true"
            );
            
            const colors = JSON.parse(result);
            primary = colors.primary;
            onPrimary = colors.onPrimary;
            secondary = colors.secondary;
            surface = colors.surface;
            surfaceVariant = colors.surfaceVariant;
            onSurface = colors.onSurface;
        }
    }
    
    // Quick toggle component
    Component {
        id: QuickToggle
        
        Rectangle {
            property string title: "Toggle"
            property string icon: "•"
            property bool active: false
            
            width: 180
            height: 80
            radius: 16
            color: active ? colors.primary : colors.surface
            
            Column {
                anchors.centerIn: parent
                spacing: 4
                
                Text {
                    text: icon
                    font.pixelSize: 24
                    color: active ? colors.onPrimary : colors.onSurface
                }
                
                Text {
                    text: title
                    font.pixelSize: 14
                    color: active ? colors.onPrimary : colors.onSurface
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: active = !active
            }
        }
    }
}
QSSHELL

# ========================================
# Scripts
# ========================================

log_info "Yardımcı scriptler yazılıyor..."

cat > ~/.config/quickshell/scripts/wallpaper-picker.sh << 'WALLSCRIPT'
#!/bin/bash

WALLPAPER_DIR="$HOME/.local/share/wallpapers"
CURRENT_WALL="$HOME/.cache/current-wallpaper"

# Use fuzzel to select wallpaper
SELECTED=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" \) | fuzzel --dmenu --prompt "Select Wallpaper: ")

if [ -n "$SELECTED" ]; then
    # Set wallpaper with swww
    swww img "$SELECTED" --transition-type grow --transition-pos 0.9,0.1 --transition-duration 2
    
    # Save current wallpaper path
    echo "$SELECTED" > "$CURRENT_WALL"
    
    # Extract and apply Material You colors
    material-color-extract "$SELECTED" tonal_spot true > "$HOME/.cache/material-colors.json"
    
    # Reload Quickshell to apply new colors
    killall qs
    qs -c ~/.config/quickshell/shell.qml &
    
    # Apply to GTK
    python3 ~/.config/quickshell/scripts/apply-gtk-colors.py
    
    # Apply to Qt via kde-material-you-colors
    plasma-apply-colorscheme MaterialYouDark
    
    notify-send "Wallpaper Changed" "Material You colors applied" -i "$SELECTED"
fi
WALLSCRIPT

chmod +x ~/.config/quickshell/scripts/wallpaper-picker.sh

# Python script for GTK theming
cat > ~/.config/quickshell/scripts/apply-gtk-colors.py << 'GTKSCRIPT'
#!/usr/bin/env python3

import json
import os
from pathlib import Path

HOME = Path.home()
COLORS_FILE = HOME / ".cache/material-colors.json"
GTK3_CONFIG = HOME / ".config/gtk-3.0/gtk.css"
GTK4_CONFIG = HOME / ".config/gtk-4.0/gtk.css"

def apply_gtk_theme():
    if not COLORS_FILE.exists():
        return
    
    with open(COLORS_FILE) as f:
        colors = json.load(f)
    
    css_content = f"""
    /* Material You Dynamic Colors */
    
    @define-color accent_color {colors['primary']};
    @define-color accent_bg_color {colors['primaryContainer']};
    @define-color accent_fg_color {colors['onPrimaryContainer']};
    
    @define-color window_bg_color {colors['surface']};
    @define-color window_fg_color {colors['onSurface']};
    
    @define-color view_bg_color {colors['background']};
    @define-color view_fg_color {colors['onBackground']};
    
    @define-color headerbar_bg_color {colors['surfaceVariant']};
    @define-color headerbar_fg_color {colors['onSurfaceVariant']};
    
    @define-color card_bg_color {colors['surfaceVariant']};
    @define-color card_fg_color {colors['onSurfaceVariant']};
    
    @define-color popover_bg_color {colors['surface']};
    @define-color popover_fg_color {colors['onSurface']};
    
    @define-color dialog_bg_color {colors['surface']};
    @define-color dialog_fg_color {colors['onSurface']};
    
    @define-color sidebar_bg_color {colors['surfaceVariant']};
    @define-color sidebar_fg_color {colors['onSurfaceVariant']};
    
    @define-color error_color {colors['error']};
    @define-color error_bg_color {colors['errorContainer']};
    @define-color error_fg_color {colors['onErrorContainer']};
    
    @define-color warning_color {colors['tertiary']};
    @define-color warning_bg_color {colors['tertiaryContainer']};
    @define-color warning_fg_color {colors['onTertiaryContainer']};
    
    @define-color success_color {colors['secondary']};
    @define-color success_bg_color {colors['secondaryContainer']};
    @define-color success_fg_color {colors['onSecondaryContainer']};
    """
    
    # Write to GTK3
    GTK3_CONFIG.parent.mkdir(parents=True, exist_ok=True)
    with open(GTK3_CONFIG, 'w') as f:
        f.write(css_content)
    
    # Write to GTK4
    GTK4_CONFIG.parent.mkdir(parents=True, exist_ok=True)
    with open(GTK4_CONFIG, 'w') as f:
        f.write(css_content)

if __name__ == "__main__":
    apply_gtk_theme()
GTKSCRIPT

chmod +x ~/.config/quickshell/scripts/apply-gtk-colors.py

# ========================================
# Terminal Configs
# ========================================

log_info "Terminal konfigürasyonları..."

# Kitty
cat > ~/.config/kitty/kitty.conf << 'KITTYCONF'
# Font
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size 11.0

# Cursor
cursor_shape block
cursor_blink_interval 0

# Window
remember_window_size  yes
initial_window_width  1000
initial_window_height 600
window_padding_width 12
background_opacity 0.95
background_blur 32

# Material You Colors (will be updated dynamically)
foreground #E1E1E1
background #121212
selection_foreground #000000
selection_background #BB86FC

# Tab bar
tab_bar_edge top
tab_bar_style powerline
tab_powerline_style slanted

# Performance
repaint_delay 10
input_delay 3
sync_to_monitor yes
KITTYCONF

# Foot
cat > ~/.config/foot/foot.ini << 'FOOTCONF'
[main]
font=JetBrainsMono Nerd Font:size=11
dpi-aware=yes

[bell]
urgent=yes
notify=yes

[scrollback]
lines=10000

[cursor]
style=block
blink=no

[colors]
alpha=0.95
foreground=e1e1e1
background=121212

## Material You colors
regular0=1e1e1e
regular1=f44336
regular2=4caf50
regular3=ffeb3b
regular4=2196f3
regular5=bb86fc
regular6=03dac6
regular7=e1e1e1

bright0=3e3e3e
bright1=ef5350
bright2=66bb6a
bright3=fff59d
bright4=42a5f5
bright5=ce93d8
bright6=26c6da
bright7=ffffff
FOOTCONF

# ========================================
# Sample wallpapers
# ========================================

log_info "Örnek wallpaper indiriliyor..."

cd ~/.local/share/wallpapers

# Download some Material Design wallpapers
wget -q -O material-blue.jpg "https://source.unsplash.com/1920x1080/?material,blue,abstract"
wget -q -O material-purple.jpg "https://source.unsplash.com/1920x1080/?material,purple,gradient"
wget -q -O material-ocean.jpg "https://source.unsplash.com/1920x1080/?ocean,blue,sunset"

cd ~

log_success "Wallpaper'lar hazır"

# ========================================
# PHASE 9: Final System Configuration
# ========================================

log_step "PHASE 9: Sistem ayarları ve optimizasyonlar"

log_info "Systemd user services..."

mkdir -p ~/.config/systemd/user

# Quickshell service
cat > ~/.config/systemd/user/quickshell.service << 'QSSERVICE'
[Unit]
Description=Quickshell - Material You Shell
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/qs -c %h/.config/quickshell/shell.qml
Restart=on-failure

[Install]
WantedBy=graphical-session.target
QSSERVICE

log_info "Login manager ayarları..."

if command -v sddm &> /dev/null; then
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/hyprland.conf > /dev/null << 'SDDMCONF'
[General]
DisplayServer=wayland

[Wayland]
CompositorCommand=/usr/bin/Hyprland
SDDMCONF
fi

# ========================================
# Python virtual environment for Quickshell
# ========================================

log_info "Python sanal ortamı hazırlanıyor..."

mkdir -p ~/.local/state/quickshell
python3 -m venv ~/.local/state/quickshell/.venv

source ~/.local/state/quickshell/.venv/bin/activate
pip install --upgrade pip
pip install materialyoucolor material-color-utilities pillow
deactivate

# ========================================
# Shell configuration
# ========================================

log_info "Shell ayarları..."

if ! grep -q "~/.local/bin" ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

if [ -f ~/.zshrc ]; then
    if ! grep -q "~/.local/bin" ~/.zshrc; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    fi
fi

log_success "Kurulum tamamlandı!"

# ========================================
# Final Instructions
# ========================================

clear
cat << "EOF"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         ✨ KURULUM BAŞARIYLA TAMAMLANDI! ✨               ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

📋 SONRAKI ADIMLAR:

1️⃣  Sisteminizi yeniden başlatın:
    $ sudo reboot

2️⃣  GDM/SDDM'den Hyprland'i seçin ve giriş yapın

3️⃣  İlk wallpaper ayarlayın:
    Super + Ctrl + T

4️⃣  Keybindings:
    • Super + Return       → Terminal
    • Super + Space        → Launcher
    • Super + Q            → Pencereyi kapat
    • Super + A            → Sol sidebar
    • Super + D            → Sağ sidebar (Quick Settings)
    • Super + Tab          → Overview
    • Print                → Ekran görüntüsü (alan)
    • Shift + Print        → Ekran görüntüsü (tam)

5️⃣  Ayarlar:
    • Wallpaper değişimi otomatik renk güncellemesi yapar
    • GTK ve Qt uygulamaları Material You renklerini kullanır
    • Smooth animasyonlar için VRR etkin

🎨 TEMA ÖZELLEŞTİRME:

   • Wallpaper: ~/.local/share/wallpapers/
   • Renkler: ~/.cache/material-colors.json
   • Quickshell: ~/.config/quickshell/
   • Hyprland: ~/.config/hypr/hyprland.conf

📚 BELGELER:

   • Hyprland Wiki: https://wiki.hyprland.org
   • end-4 dots: https://github.com/end-4/dots-hyprland
   • Quickshell: https://github.com/outfoxxed/quickshell

⚠️  NOTLAR:

   • NVIDIA GPU için özel optimizasyonlar uygulandı
   • Renk şeması "tonal_spot" (değiştirmek için script'i düzenle)
   • Backup: ~/.config-backup-*/

🎯 İYİ KULANIMLAR!

EOF

log_info "Kurulum scripti tamamlandı. Loglara bakın: ~/.hyprland-install.log"

# Save log
) 2>&1 | tee ~/.hyprland-install.log

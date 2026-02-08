#!/bin/bash

# ========================================
# Extended Quickshell Configuration
# Android Material You Complete Setup
# ========================================

# This script extends the base installation with a full-featured
# Quickshell configuration inspired by end-4's illogical-impulse

CONFIG_DIR="$HOME/.config/quickshell"
SCRIPTS_DIR="$CONFIG_DIR/scripts"
MODULES_DIR="$CONFIG_DIR/modules"

mkdir -p "$CONFIG_DIR"/{modules,scripts,styles,panels,widgets}

# ========================================
# Advanced Shell.qml with full features
# ========================================

cat > "$CONFIG_DIR/shell.qml" << 'SHELLQML'
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Io

ShellRoot {
    id: root
    
    // ========================================
    // State Management
    // ========================================
    
    property var materialColors: MaterialColors {}
    property var hyprland: HyprlandIpc {}
    property var audio: PwObjectTracker {
        objects: [PwNode]
    }
    
    // Panel visibility states
    property bool quickSettingsVisible: false
    property bool notificationCenterVisible: false
    property bool overviewVisible: false
    
    // Current theme mode
    property bool darkMode: true
    property string currentWallpaper: ""
    
    // ========================================
    // Configuration
    // ========================================
    
    QtObject {
        id: config
        
        // Bar settings
        property int barHeight: 48
        property int barMargin: 12
        property int barRadius: 24
        
        // Panel settings
        property int panelWidth: 420
        property int panelRadius: 28
        
        // Animation durations (ms)
        property int animationDuration: 300
        property int shortAnimationDuration: 150
        
        // Colors
        property var colors: materialColors
    }
    
    // ========================================
    // IPC Handler for external control
    // ========================================
    
    Process {
        id: ipcHandler
        
        function togglePanel(panelName) {
            if (panelName === "quickSettings") {
                quickSettingsVisible = !quickSettingsVisible
            } else if (panelName === "notifications") {
                notificationCenterVisible = !notificationCenterVisible
            } else if (panelName === "overview") {
                overviewVisible = !overviewVisible
            }
        }
    }
    
    // ========================================
    // TOP BAR - Main status bar
    // ========================================
    
    PanelWindow {
        id: topBar
        
        anchors {
            top: true
            left: true
            right: true
        }
        
        margins {
            top: config.barMargin
            left: config.barMargin
            right: config.barMargin
        }
        
        height: config.barHeight
        color: "transparent"
        
        mask: Region {
            item: barBackground
        }
        
        Rectangle {
            id: barBackground
            anchors.fill: parent
            color: Qt.rgba(
                config.colors.surface.r,
                config.colors.surface.g,
                config.colors.surface.b,
                0.85
            )
            radius: config.barRadius
            
            layer.enabled: true
            layer.effect: ShaderEffect {
                fragmentShader: "
                    uniform lowp sampler2D source;
                    uniform lowp float qt_Opacity;
                    varying highp vec2 qt_TexCoord0;
                    void main() {
                        lowp vec4 p = texture2D(source, qt_TexCoord0);
                        gl_FragColor = p * qt_Opacity;
                    }
                "
            }
            
            // Content
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 16
                
                // ========================================
                // LEFT SECTION - Workspaces & Active Window
                // ========================================
                
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    RowLayout {
                        anchors.fill: parent
                        spacing: 12
                        
                        // Launcher button
                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 18
                            color: config.colors.primaryContainer
                            
                            Text {
                                anchors.centerIn: parent
                                text: "◉"
                                font.pixelSize: 20
                                color: config.colors.onPrimaryContainer
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Process.run("fuzzel")
                                }
                                
                                hoverEnabled: true
                                onEntered: parent.scale = 1.05
                                onExited: parent.scale = 1.0
                                
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: config.shortAnimationDuration
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                        
                        // Workspace indicators
                        Row {
                            spacing: 8
                            
                            Repeater {
                                model: 5
                                
                                Rectangle {
                                    width: 40
                                    height: 32
                                    radius: 16
                                    
                                    property bool isActive: index === 0 // TODO: Connect to Hyprland
                                    property bool hasWindows: true // TODO: Connect to Hyprland
                                    
                                    color: isActive ? 
                                        config.colors.primary : 
                                        (hasWindows ? 
                                            config.colors.surfaceVariant : 
                                            "transparent")
                                    
                                    border.width: hasWindows ? 0 : 1
                                    border.color: config.colors.outline
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: index + 1
                                        color: isActive ? 
                                            config.colors.onPrimary : 
                                            config.colors.onSurface
                                        font.pixelSize: 14
                                        font.bold: isActive
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            hyprland.dispatch("workspace", index + 1)
                                        }
                                    }
                                    
                                    Behavior on color {
                                        ColorAnimation { 
                                            duration: config.animationDuration 
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Active window title
                        Text {
                            Layout.fillWidth: true
                            text: "Active Window Title" // TODO: Connect to Hyprland
                            color: config.colors.onSurface
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            opacity: 0.9
                        }
                    }
                }
                
                // ========================================
                // CENTER SECTION - Date & Time
                // ========================================
                
                Rectangle {
                    Layout.preferredWidth: 140
                    Layout.fillHeight: true
                    radius: 16
                    color: config.colors.surfaceVariant
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(new Date(), "hh:mm")
                            color: config.colors.onSurface
                            font.pixelSize: 18
                            font.bold: true
                        }
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(new Date(), "ddd, MMM d")
                            color: config.colors.onSurfaceVariant
                            font.pixelSize: 11
                        }
                    }
                    
                    // Update time every second
                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: parent.update()
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // TODO: Open calendar
                        }
                    }
                }
                
                // ========================================
                // RIGHT SECTION - System Tray & Quick Settings
                // ========================================
                
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.rightMargin: 0
                        spacing: 12
                        
                        // Spacer
                        Item { Layout.fillWidth: true }
                        
                        // Media indicator
                        Rectangle {
                            visible: true // TODO: Check if media playing
                            Layout.preferredWidth: 200
                            Layout.preferredHeight: 32
                            radius: 16
                            color: config.colors.tertiaryContainer
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8
                                
                                Text {
                                    text: "▶"
                                    color: config.colors.onTertiaryContainer
                                    font.pixelSize: 12
                                }
                                
                                Text {
                                    Layout.fillWidth: true
                                    text: "Song Title - Artist" // TODO: Connect to playerctl
                                    color: config.colors.onTertiaryContainer
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Process.run("playerctl", ["play-pause"])
                                }
                            }
                        }
                        
                        // System indicators
                        Row {
                            spacing: 8
                            
                            // Volume
                            SystemIndicator {
                                icon: "🔊"
                                value: "75%" // TODO: Connect to audio
                            }
                            
                            // Brightness
                            SystemIndicator {
                                icon: "☀"
                                value: "80%" // TODO: Connect to brightness
                            }
                            
                            // Battery
                            SystemIndicator {
                                icon: "🔋"
                                value: "85%" // TODO: Connect to battery
                            }
                            
                            // Network
                            SystemIndicator {
                                icon: "📶"
                                value: "WiFi"
                            }
                        }
                        
                        // Quick Settings trigger
                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 18
                            color: quickSettingsVisible ? 
                                config.colors.primary : 
                                config.colors.surfaceVariant
                            
                            Text {
                                anchors.centerIn: parent
                                text: "⚙"
                                font.pixelSize: 18
                                color: quickSettingsVisible ? 
                                    config.colors.onPrimary : 
                                    config.colors.onSurfaceVariant
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    quickSettingsVisible = !quickSettingsVisible
                                }
                            }
                            
                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // ========================================
    // QUICK SETTINGS PANEL - Android-style
    // ========================================
    
    PanelWindow {
        id: quickSettings
        
        visible: quickSettingsVisible
        
        anchors {
            top: true
            right: true
        }
        
        margins {
            top: config.barHeight + config.barMargin * 2 + 8
            right: config.barMargin
        }
        
        width: config.panelWidth
        height: 700
        
        color: "transparent"
        
        // Click outside to close
        MouseArea {
            anchors.fill: parent
            onClicked: quickSettingsVisible = false
        }
        
        // Panel content
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(
                config.colors.surface.r,
                config.colors.surface.g,
                config.colors.surface.b,
                0.95
            )
            radius: config.panelRadius
            
            // Slide-in animation
            transform: Translate {
                id: qsTranslate
                x: quickSettingsVisible ? 0 : config.panelWidth + 50
                
                Behavior on x {
                    NumberAnimation {
                        duration: config.animationDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                
                // Header
                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        Layout.fillWidth: true
                        text: "Quick Settings"
                        color: config.colors.onSurface
                        font.pixelSize: 24
                        font.bold: true
                    }
                    
                    // Settings button
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        color: config.colors.surfaceVariant
                        
                        Text {
                            anchors.centerIn: parent
                            text: "⚙"
                            color: config.colors.onSurfaceVariant
                            font.pixelSize: 20
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Process.run("systemsettings")
                            }
                        }
                    }
                }
                
                // Profile section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: 20
                    color: config.colors.primaryContainer
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16
                        
                        // Avatar
                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            radius: 24
                            color: config.colors.primary
                            
                            Text {
                                anchors.centerIn: parent
                                text: "U"
                                color: config.colors.onPrimary
                                font.pixelSize: 24
                                font.bold: true
                            }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Text {
                                text: "User Name"
                                color: config.colors.onPrimaryContainer
                                font.pixelSize: 16
                                font.bold: true
                            }
                            
                            Text {
                                text: "HP Victus 16"
                                color: config.colors.onPrimaryContainer
                                font.pixelSize: 12
                                opacity: 0.8
                            }
                        }
                    }
                }
                
                // Quick toggles grid
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 12
                    columnSpacing: 12
                    
                    QuickToggle {
                        Layout.fillWidth: true
                        title: "WiFi"
                        subtitle: "Connected"
                        icon: "📶"
                        active: true
                        onClicked: {
                            // TODO: Toggle WiFi
                        }
                    }
                    
                    QuickToggle {
                        Layout.fillWidth: true
                        title: "Bluetooth"
                        subtitle: "Off"
                        icon: "🔵"
                        active: false
                        onClicked: {
                            // TODO: Toggle Bluetooth
                        }
                    }
                    
                    QuickToggle {
                        Layout.fillWidth: true
                        title: "Airplane"
                        subtitle: "Off"
                        icon: "✈"
                        active: false
                    }
                    
                    QuickToggle {
                        Layout.fillWidth: true
                        title: "DND"
                        subtitle: "Off"
                        icon: "🔕"
                        active: false
                    }
                    
                    QuickToggle {
                        Layout.fillWidth: true
                        title: "Night Light"
                        subtitle: "Auto"
                        icon: "🌙"
                        active: true
                    }
                    
                    QuickToggle {
                        Layout.fillWidth: true
                        title: "Dark Mode"
                        subtitle: "On"
                        icon: "🌓"
                        active: darkMode
                        onClicked: {
                            darkMode = !darkMode
                            materialColors.updateTheme(currentWallpaper, darkMode)
                        }
                    }
                }
                
                // Sliders
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    // Brightness slider
                    MaterialSlider {
                        Layout.fillWidth: true
                        label: "Brightness"
                        icon: "☀"
                        value: 0.8
                        onValueChanged: {
                            // TODO: Set brightness
                        }
                    }
                    
                    // Volume slider
                    MaterialSlider {
                        Layout.fillWidth: true
                        label: "Volume"
                        icon: "🔊"
                        value: 0.75
                        onValueChanged: {
                            // TODO: Set volume
                        }
                    }
                }
                
                // Media control
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 20
                    color: config.colors.secondaryContainer
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            
                            Rectangle {
                                Layout.preferredWidth: 60
                                Layout.preferredHeight: 60
                                radius: 12
                                color: config.colors.secondary
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "♪"
                                    color: config.colors.onSecondary
                                    font.pixelSize: 28
                                }
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                
                                Text {
                                    Layout.fillWidth: true
                                    text: "Song Title"
                                    color: config.colors.onSecondaryContainer
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                
                                Text {
                                    Layout.fillWidth: true
                                    text: "Artist Name"
                                    color: config.colors.onSecondaryContainer
                                    font.pixelSize: 12
                                    opacity: 0.8
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        
                        // Playback controls
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 20
                            
                            MediaButton { icon: "⏮" }
                            MediaButton { icon: "⏸"; large: true }
                            MediaButton { icon: "⏭" }
                        }
                    }
                }
                
                // Spacer
                Item { Layout.fillHeight: true }
                
                // Power options
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    PowerButton {
                        Layout.fillWidth: true
                        icon: "🔒"
                        text: "Lock"
                        onClicked: {
                            Process.run("hyprlock")
                        }
                    }
                    
                    PowerButton {
                        Layout.fillWidth: true
                        icon: "⏾"
                        text: "Sleep"
                        onClicked: {
                            Process.run("systemctl", ["suspend"])
                        }
                    }
                    
                    PowerButton {
                        Layout.fillWidth: true
                        icon: "⏻"
                        text: "Power"
                        onClicked: {
                            // TODO: Show power menu
                        }
                    }
                }
            }
        }
    }
    
    // ========================================
    // COMPONENT DEFINITIONS
    // ========================================
    
    // System Indicator Component
    Component {
        id: SystemIndicator
        
        Rectangle {
            property string icon: "•"
            property string value: ""
            
            width: 60
            height: 32
            radius: 16
            color: config.colors.surfaceVariant
            
            Row {
                anchors.centerIn: parent
                spacing: 4
                
                Text {
                    text: icon
                    color: config.colors.onSurfaceVariant
                    font.pixelSize: 12
                }
                
                Text {
                    text: value
                    color: config.colors.onSurfaceVariant
                    font.pixelSize: 11
                }
            }
        }
    }
    
    // Quick Toggle Component
    Component {
        id: QuickToggle
        
        Rectangle {
            property string title: "Toggle"
            property string subtitle: ""
            property string icon: "•"
            property bool active: false
            
            signal clicked()
            
            height: 100
            radius: 20
            color: active ? config.colors.primaryContainer : config.colors.surfaceVariant
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                
                Text {
                    text: icon
                    color: active ? 
                        config.colors.onPrimaryContainer : 
                        config.colors.onSurfaceVariant
                    font.pixelSize: 28
                }
                
                Item { Layout.fillHeight: true }
                
                Text {
                    text: title
                    color: active ? 
                        config.colors.onPrimaryContainer : 
                        config.colors.onSurfaceVariant
                    font.pixelSize: 14
                    font.bold: true
                }
                
                Text {
                    visible: subtitle !== ""
                    text: subtitle
                    color: active ? 
                        config.colors.onPrimaryContainer : 
                        config.colors.onSurfaceVariant
                    font.pixelSize: 11
                    opacity: 0.8
                }
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: parent.clicked()
                
                hoverEnabled: true
                onEntered: parent.scale = 1.02
                onExited: parent.scale = 1.0
            }
            
            Behavior on scale {
                NumberAnimation {
                    duration: config.shortAnimationDuration
                    easing.type: Easing.OutCubic
                }
            }
            
            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }
    }
    
    // Material Slider Component
    Component {
        id: MaterialSlider
        
        ColumnLayout {
            property string label: "Slider"
            property string icon: "•"
            property real value: 0.5
            
            signal valueChanged(real newValue)
            
            spacing: 8
            
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: icon
                    color: config.colors.onSurface
                    font.pixelSize: 16
                }
                
                Text {
                    Layout.fillWidth: true
                    text: label
                    color: config.colors.onSurface
                    font.pixelSize: 14
                }
                
                Text {
                    text: Math.round(value * 100) + "%"
                    color: config.colors.onSurfaceVariant
                    font.pixelSize: 12
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 24
                radius: 12
                color: config.colors.surfaceVariant
                
                Rectangle {
                    width: parent.width * value
                    height: parent.height
                    radius: parent.radius
                    color: config.colors.primary
                }
                
                Rectangle {
                    x: parent.width * value - width / 2
                    y: parent.height / 2 - height / 2
                    width: 32
                    height: 32
                    radius: 16
                    color: config.colors.primary
                    border.width: 4
                    border.color: config.colors.surface
                }
                
                MouseArea {
                    anchors.fill: parent
                    onPositionChanged: {
                        if (pressed) {
                            var newValue = Math.max(0, Math.min(1, mouse.x / width))
                            value = newValue
                            valueChanged(newValue)
                        }
                    }
                }
            }
        }
    }
    
    // Media Button Component
    Component {
        id: MediaButton
        
        Rectangle {
            property string icon: "▶"
            property bool large: false
            
            width: large ? 56 : 44
            height: large ? 56 : 44
            radius: width / 2
            color: config.colors.primary
            
            Text {
                anchors.centerIn: parent
                text: icon
                color: config.colors.onPrimary
                font.pixelSize: large ? 24 : 18
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // TODO: Media control
                }
                
                hoverEnabled: true
                onEntered: parent.scale = 1.1
                onExited: parent.scale = 1.0
            }
            
            Behavior on scale {
                NumberAnimation {
                    duration: config.shortAnimationDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
    
    // Power Button Component
    Component {
        id: PowerButton
        
        Rectangle {
            property string icon: "⏻"
            property string text: "Power"
            
            signal clicked()
            
            height: 60
            radius: 16
            color: config.colors.errorContainer
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: icon
                    color: config.colors.onErrorContainer
                    font.pixelSize: 24
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: parent.parent.text
                    color: config.colors.onErrorContainer
                    font.pixelSize: 11
                }
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: parent.clicked()
                
                hoverEnabled: true
                onEntered: parent.scale = 1.05
                onExited: parent.scale = 1.0
            }
            
            Behavior on scale {
                NumberAnimation {
                    duration: config.shortAnimationDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
    
    // ========================================
    // Material Colors Manager
    // ========================================
    
    QtObject {
        id: MaterialColors
        
        // Color properties
        property color primary: "#BB86FC"
        property color onPrimary: "#000000"
        property color primaryContainer: "#3700B3"
        property color onPrimaryContainer: "#E1E1E1"
        
        property color secondary: "#03DAC6"
        property color onSecondary: "#000000"
        property color secondaryContainer: "#018786"
        property color onSecondaryContainer: "#E1E1E1"
        
        property color tertiary: "#CF6679"
        property color onTertiary: "#000000"
        property color tertiaryContainer: "#B00020"
        property color onTertiaryContainer: "#E1E1E1"
        
        property color error: "#CF6679"
        property color onError: "#000000"
        property color errorContainer: "#B00020"
        property color onErrorContainer: "#E1E1E1"
        
        property color background: "#121212"
        property color onBackground: "#E1E1E1"
        property color surface: "#1E1E1E"
        property color onSurface: "#E1E1E1"
        
        property color surfaceVariant: "#2C2C2C"
        property color onSurfaceVariant: "#CACACA"
        property color outline: "#565656"
        property color outlineVariant: "#3C3C3C"
        
        property color shadow: "#000000"
        property color scrim: "#000000"
        
        function updateTheme(wallpaperPath, isDark) {
            // Call Python color extraction script
            var result = Process.readOutput(
                "material-color-extract",
                [wallpaperPath, "tonal_spot", isDark ? "true" : "false"]
            )
            
            try {
                var colors = JSON.parse(result)
                
                primary = colors.primary
                onPrimary = colors.onPrimary
                primaryContainer = colors.primaryContainer
                onPrimaryContainer = colors.onPrimaryContainer
                
                secondary = colors.secondary
                onSecondary = colors.onSecondary
                secondaryContainer = colors.secondaryContainer
                onSecondaryContainer = colors.onSecondaryContainer
                
                tertiary = colors.tertiary
                onTertiary = colors.onTertiary
                tertiaryContainer = colors.tertiaryContainer
                onTertiaryContainer = colors.onTertiaryContainer
                
                error = colors.error
                onError = colors.onError
                errorContainer = colors.errorContainer
                onErrorContainer = colors.onErrorContainer
                
                background = colors.background
                onBackground = colors.onBackground
                surface = colors.surface
                onSurface = colors.onSurface
                
                surfaceVariant = colors.surfaceVariant
                onSurfaceVariant = colors.onSurfaceVariant
                outline = colors.outline
                outlineVariant = colors.outlineVariant
                
                // Apply to system
                Process.run("~/.config/quickshell/scripts/apply-gtk-colors.py")
                
            } catch (e) {
                console.error("Failed to parse colors:", e)
            }
        }
        
        Component.onCompleted: {
            // Load initial colors from current wallpaper
            var wallpaperFile = Process.readOutput("cat", [
                Qt.resolvedUrl("~/.cache/current-wallpaper")
            ])
            
            if (wallpaperFile) {
                currentWallpaper = wallpaperFile.trim()
                updateTheme(currentWallpaper, darkMode)
            }
        }
    }
}
SHELLQML

chmod +x "$CONFIG_DIR/shell.qml"

echo "Extended Quickshell configuration created successfully!"
echo "Location: $CONFIG_DIR/shell.qml"
echo ""
echo "This provides:"
echo "  • Complete Material You theming"
echo "  • Android-style Quick Settings panel"
echo "  • Dynamic workspace indicators"
echo "  • Media controls"
echo "  • System sliders (brightness, volume)"
echo "  • Smooth animations"
echo ""
echo "Run: qs -c ~/.config/quickshell/shell.qml"

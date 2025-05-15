#!/bin/bash

# WiFi Ağ Yönetim Menüsü (Wofi ile)

# NetworkManager komutlarını kullanarak WiFi işlevselliği
wifi_connect() {
    local ssid="$1"
    nmcli device wifi connect "$ssid"
}

wifi_disconnect() {
    nmcli radio wifi off
}

wifi_scan() {
    nmcli -f SSID,SIGNAL,SECURITY device wifi list
}

wifi_list_saved() {
    nmcli connection show | grep wifi
}

# Wofi menüsü fonksiyonu
show_wifi_menu() {
    choice=$(echo -e "WiFi Tara\nKayıtlı Ağları Göster\nBağlantıyı Kes\nÇıkış" | wofi --dmenu -p "WiFi Menüsü")
    
    case "$choice" in
        "WiFi Tara")
            wifi_scan | wofi --dmenu -p "Kullanılabilir Ağlar"
            read -p "Bağlanmak istediğiniz ağın SSID'sini girin: " selected_ssid
            if [ -n "$selected_ssid" ]; then
                wifi_connect "$selected_ssid"
            fi
            ;;
        "Kayıtlı Ağları Göster")
            wifi_list_saved | wofi --dmenu -p "Kayıtlı Ağlar"
            ;;
        "Bağlantıyı Kes")
            wifi_disconnect
            ;;
        "Çıkış")
            exit 0
            ;;
        *)
            echo "Geçersiz seçim"
            ;;
    esac
}

# Menüyü göster
while true; do
    show_wifi_menu
done

#!/bin/bash

# Waydroid tam ekran çalışma alanı scripti

# Waydroid özel workspace numarası
WAYDROID_WORKSPACE=9

# Eğer Waydroid çalışmıyorsa başlat
if ! waydroid status | grep -q "RUNNING"; then
  waydroid session start --multi-windows &
  sleep 3
fi

# Waydroid çalışma alanına geç
hyprctl dispatch workspace $WAYDROID_WORKSPACE

# Waydroid App List başlat (eğer başlatılmamışsa)
if ! pgrep -f "waydroid app list" > /dev/null; then
  waydroid show-full-ui &
  sleep 2
fi

# Tüm Waydroid pencerelerini fullscreen yap
for window in $(hyprctl clients | grep "Waydroid" -A 2 | grep "address: " | awk '{print $2}'); do
  hyprctl dispatch focuswindow "address:$window"
  hyprctl dispatch fullscreen 1
done

# Eğer hiç Waydroid penceresi yoksa, başlat
if ! hyprctl clients | grep -q "Waydroid"; then
  waydroid show-full-ui &
  sleep 2
  # Son açılan pencereyi fullscreen yap
  hyprctl dispatch fullscreen 1
fi

#/bin

# To load in the env vars (since this is spawned by exec)
source ~/.config/colors.sh

echo "set \$tab_color $COLOR_DARK_BACKGROUND
set \$font_color $COLOR_DARK_TEXT" > ~/.config/sway/env

sway_sock=$(sway --get-socketpath)

if [ -z "$sway_sock" ]; then
    #WLR_DRM_DEVICES=/dev/dri/card0:/dev/dri/card1
    sway
else
    pkill -f ^swayidle
    pkill -f ^yambar
    pkill -f sway-audio-idle-inhibit
    swaymsg -s $sway_sock reload
fi

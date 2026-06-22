#!/usr/bin/env bash

LOCK="   Lock"
SUSPEND="   Suspend"
LOGOUT="   Logout"
REBOOT="   Reboot"
SHUTDOWN="   Shutdown"

CHOICE=$(printf "%s\n" "$LOCK" "$SUSPEND" "$LOGOUT" "$REBOOT" "$SHUTDOWN" \
    | rofi -dmenu \
           -p "  Power" \
           -selected-row 0 \
           -theme ~/.config/rofi/powermenu.rasi)

case "$CHOICE" in
    "$LOCK")     hyprlock ;;
    "$SUSPEND")  loginctl suspend ;;
    "$LOGOUT")   hyprctl dispatch exit ;;
    "$REBOOT")   systemctl reboot ;;
    "$SHUTDOWN") systemctl poweroff ;;
esac

#!/bin/sh
exec /usr/bin/tuigreet \
  --time \
  --time-format '%a %d %b  %H:%M' \
  --remember \
  --remember-user-session \
  --user-menu \
  --user-menu-min-uid 1000 \
  --asterisks \
  --asterisks-char '•' \
  --width 72 \
  --window-padding 1 \
  --container-padding 1 \
  --prompt-padding 1 \
  --power-shutdown 'systemctl poweroff' \
  --power-reboot 'systemctl reboot' \
  --sessions /usr/share/wayland-sessions \
  --theme 'border=#b4befe;text=#cdd6f4;prompt=#cba6f7;time=#89b4fa;action=#a6e3a1;button=#313244;container=#1e1e2e;input=#cdd6f4;greet=#cba6f7'

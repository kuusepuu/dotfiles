#!/bin/bash
# AMD discrete GPU stats (card1 = dGPU, hwmon1 = amdgpu dGPU sensor)
#  = nf processor icon,  = fa-thermometer-half
GPU_ICON=$(printf '')
TEMP_ICON=$(printf '')

GPU_BUSY=$(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null || echo 0)
GPU_TEMP=$(awk '{printf "%d", $1/1000}' /sys/class/hwmon/hwmon1/temp1_input 2>/dev/null || echo 0)
VRAM_USED=$(awk '{printf "%.1f", $1/1073741824}' /sys/class/drm/card1/device/mem_info_vram_used 2>/dev/null || echo 0)
VRAM_TOTAL=$(awk '{printf "%.0f", $1/1073741824}' /sys/class/drm/card1/device/mem_info_vram_total 2>/dev/null || echo 0)

printf '{"text":"%s %s%%  %s %s°C","tooltip":"VRAM: %sG / %sG | Busy: %s%%"}\n' \
    "$GPU_ICON" "$GPU_BUSY" "$TEMP_ICON" "$GPU_TEMP" "$VRAM_USED" "$VRAM_TOTAL" "$GPU_BUSY"

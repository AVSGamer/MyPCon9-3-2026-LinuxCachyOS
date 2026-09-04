#!/bin/bash
export DISPLAY=:0
# 1. Create the new mode inside xrandr
xrandr --newmode "1200x540_60.00"   51.00  1200 1240 1360 1520  540 543 553 562 -hsync +vsync
# 2. Bind the new mode to your display output (replace HDMI-1 with your actual output name)
xrandr --addmode DP-0 "1200x540_60.00"
# 3. Pure Activation (KScreen will handle positioning automatically)
xrandr --output DP-0 --mode "1200x540_60.00" --left-of HDMI-0 --panning 1200x540+0+360
exit 0

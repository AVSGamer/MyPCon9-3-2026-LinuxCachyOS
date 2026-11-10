#
# Created by: Khayeel(https://github.com/AVSGamer)
# This a script I made and use to have OBS with
# VritualCamera Mode ON and Beam Eye
# Tracker(Steam PLatform) # autostart on system
# startup of my personal PC.
#!/usr/bin/env bash


# 1. Launch OBS in the background after 15 seconds
(sleep 15 && flatpak run com.obsproject.Studio --startvirtualcam --disable-missing-files-check --unattended) &

# 2. Launch Beam Eye Tracker in the background after 30 seconds using the correct 'run' handler
(sleep 30 && steam steam://run/2375780) &

# 3. Instantly exits and frees up your desktop session memory right away!
exit 0

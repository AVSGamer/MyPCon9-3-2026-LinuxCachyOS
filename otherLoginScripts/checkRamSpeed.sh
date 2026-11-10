# Created by: Khayeel(https://github.com/AVSGamer)
# This is a simple combination of builtin commands
# in Linux to have the PC automatically save the
# output of a command into a text(.txt) file
# pertaining to the current Ram Sticks configured
# Speed. XMP Profile ON/OFF Checker for MangoHUD
# to read or any other file/program that can
# read a text(.txt) file.
#!/bin/bash
sudo /usr/bin/dmidecode --type memory | grep -m 1 Speed | grep -oE '[0-9]+ MT/s' > ~/RamSpeed.txt
exit 0

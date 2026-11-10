# MyPCon9-3-2026-LinuxCachyOS
Details/Specifications and Custom Configuration Scripts I use on my Personal PC starting from Sept 3 of 2026.

My Hardware:
PC Case - Generic Black with Full Sized 5.25" Bay + 2(12025) Fan Slots + 1(90mm or 80mm) Back Fan Slot
PC Case Dimensions - 310mm(L)x187mm(W)x350mm(H) = 20.3L in Volume
Case Fans Setup - Side Panel Slot as outflow, Front Panel Slot as intake, Back Panel Slot still unfilled and undecided whether intake or outflow, will need to check current airflow.
CPU(Central Processing Unit) - Ryzen 5 5500
Motherboard - ASRock B450m Steel Legend
Motherboard Bios Version - P10.60
GPU(Graphical Processing Unit) - Zotac Mini Nvidia GTX 1070 8GB
PSU(Power Supply Unit) - FSP Dagger Pro SFX Modular 650 Watts
RAM(Random Access Memory) - Kingston HyperX Fury 8GBx2 3200MHz(via XMP Profile in Motherboard Bios)
SATA Connected - 5.25" CD-RW/DVD-R Drive
USB 3.2 Gen2 at the Back of the Motherboard - FanXiang MD85 SSD Enclosure that has my OS
FanXiang MD85 SSD Enclosure - Housing my ADATA XPG SSD 1TB


Optimizations on the OS Level:
Adding a disk-based SwapRam Size double my actual Physical RAM Total Size.
Installing CachyOS' Gaming Packages.
Applying a fix to the PipeWire's Audio Streams Quantization to reduce crackling/popping audio at times.
Setting the Power Plan to Balanced but using a Proton Command(game-performance %command%) to run my games and change it to High Performance while gaming only.

SwapRam:
Option 1: Increase ZRAM Allocation (Recommended)
Because ZRAM compresses data heavily (often up to a 2:1 or 3:1 ratio using zstd), you can safely configure it to use double your physical memory size without actually consuming that much raw RAM.
Open a terminal and open or create the zram-generator configuration file:
sudo nano /etc/systemd/zram-generator.conf
Use code with caution.
Paste or modify the configuration to use a multiplier (e.g., ram * 2 for double your physical RAM size):
[zram0]
Use code with caution.
zram-size = ram * ( 2 / 3 )
zram was x2 of ram before, changed to 2/3 for more stability to prevent crashes/hanging.
compression-algorithm = zstd
swap-priority = 100
fs-type = swap

Save and close the file, if using nano; Ctrl+O, Enter, then Ctrl+X.
Restart the generator service to apply changes immediately:
Use code with caution.
sudo systemctl restart systemd-zram-setup@zram0.service

Option 2: Add a Traditional Backing Swap File (Disk Fallback)
If you are worried about running completely out of physical memory during heavy workloads (like compilation or intense multitasking) and want an overflow area on your SSD/HDD, you can create a permanent swap file.

Create the file allocation (e.g., creating an 8GB swap file):
Use code with caution.
sudo dd if=/dev/zero of=/swapfile bs=1M count=8192
(Change count=8192 to count=16384 if you want 16GB, etc.)

Secure the permissions so only the root user can access it:
sudo chmod 600 /swapfile

Format the file into swap format:
sudo mkswap /swapfile

Activate the swap file temporarily:
sudo swapon /swapfile

Make it permanent by adding it to your file systems table. Run this command to append it to /etc/fstab:
echo '/swapfile none swap sw,pri=10 0 0' | sudo tee -a /etc/fstab

Note: Keeping pri=10 ensures that CachyOS prefers your ultra-fast ZRAM (pri=100) first, only spilling over to your storage disk when your system absolutely needs it.

Verification
To check that your new swap spaces are detected and priorities are set up correctly, run:
swapon --show

You should see zram0 listed with a high priority and, if you chose Option 2, your /swapfile listed with a lower priority.

PipeWire Audio Quantization Fix: (You can also use pw-top to check it via terminal then screenshot it to send to AI LLM to assess it.)

Locally to user space:
Use code with caution.
mkdir -p ~/.config/pipewire/pipewire.flatpak update
conf.d/
nano ~/.config/pipewire/pipewire.conf.d/99-hardware-quant.conf
inside the conf file:
context.properties = {
    default.clock.quantum       = 1024
    default.clock.min-quantum   = 512
    default.clock.max-quantum   = 1024
    default.clock.rate          = 48000
    default.clock.allowed-rates = [ 48000 ]
}

#Restart the service
Use code with caution.
systemctl --user restart wireplumber pipewire pipewire-pulse

Global to entire system across users:
sudo mkdir -p /etc/pipewire/pipewire.conf.d/
sudo nano /etc/pipewire/pipewire.conf.d/99-hardware-quant.conf
inside that conf file:
context.properties = {
    default.clock.quantum       = 1024
    default.clock.min-quantum   = 512
    default.clock.max-quantum   = 1024
    default.clock.rate          = 48000
    default.clock.allowed-rates = [ 48000 ]
}

For when using the Global Version:
sudo nano /etc/pipewire/pipewire.conf.d/99-sample-rate.conf
inside that conf file:
context.properties = {
    default.clock.rate        = 48000
    default.clock.allowed-rates = [ 44100 48000 ]
}

#Restart the service
Use code with caution.
systemctl --user restart wireplumber pipewire pipewire-pulse

System Maintenance via Commandline:

Ever got stuck in an endless loop of trying to install some packages that should be in your repository/mirrorlist but not finding them?
Visit the CachyOS Official Website to look for instructions on how to get the official pacman.conf if you need to restore it.

Removing Database(db-lock) locks and updating/upgrade via terminal:
Use code with caution.
sudo rm -f /var/lib/pacman/db.lck
sudo pacman -Scc #This cleans unused ?packages/files?
sudo pacman -Syyu

The CachyOS Hardware Detection Tool to Reset:
#CachyOS maintains a custom hardware automation layer called chwd. We can pass the -f (force) flag to it, which instructs the system to #completely scan your PC Hardware, purge any legacy parameters, and pull down the exact pre-compiled, rolling release driver profile #recommended for your active CachyOS kernel setup right now.
sudo chwd -a -f
#It will automatically download the correct rolling release drivers and reconfigure your system defaults.
#If you encounter something like dependency/conflicts with another package use below to remove them then run chwd with those flags again.

Removing installed packages/apps:
sudo pacman -Rns <package-name>
sudo pacman -Rdd <package-name>

Better install OBS from Flatpak rather than the native install via the pacman repos if you plan on using it since this system's NVENC Encoder currently only works from that source. And that NVENC is massive in performance overhead reduction.

Since I am using X11, it uses the xorg.conf file inside the /etc/X11/ directory but sometimes it might not show up there, regardless you're really not supposed to edit these kinds of system level configuration files but rather create another file that would be appended to it. It's usually the the same file extensions ".conf" in a directory "xorg.conf.d" in the same directory as the main xorg.conf supposed to be.

You can use dmesg like below to see the logs of your system, in this case it's filtering to show only lines that has the words in the apostrophes, the '|' bar or, "I forgot what it's called" translates to the logical operator "OR". This below is looking for usb events and firewall/network events that got rejected or blocked:
sudo dmesg | grep -Ei 'usb|BLOCK|DROP|REJECT'

You can also use the above to check which of your devices in your household's local internet network is trying to send signals to devices in your same network. Via first knowing what IP Addresses your network-capable devices use and reading for the SRC(Source) and DST(Destination) IP Addresses of the logged "packets/requests". A way to know what their IP Address is if the device has a User Interface to show it usually under the "WiFi Settings/Properties" if not then you can configure your local network(router/modem) to specify which IP Addresses you want to bind to a device MAC Address so that the device only uses that IP Address everytime. It's good practice for local internet network management alongside, MAC Filtering and explicitly specifying how many IP Addresses your network may serve so as to limit leasing of IP Addresses for anyone trying to connect that is not registered in the network.

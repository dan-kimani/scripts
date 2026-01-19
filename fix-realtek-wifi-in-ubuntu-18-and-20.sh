# download realtek wifi drivers
wget https://github.com/lwfinger/rtlwifi_new/archive/master.zip

# unzip
unzip master.zip

# change working directory
cd rtlwifi_new-master

# build and install drivers
make
sudo make install 
sudo modprobe -rv rtl8723be
sudo modprobe -v rtl8723be ant_sel=2

# your wifi driver might have a different name, mine is wlo1,
# to scan yours, run iwconfig, the first result has the driver name, replace wlo1 with your driver name
sudo ip link set wlo1 up
sudo iw dev wlo1 scan

# this will make this change persistent through reboots,
# remember to run these commands every time you upgrade your kernel
echo "options rtl8723be ant_sel=2" | sudo tee /etc/modprobe.d/50-rtl8723be.conf


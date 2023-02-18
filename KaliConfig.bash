#!/usr/bin/env bash

### Main Script
echo "127.0.0.1	kali" >> /etc/hosts
apt-mark hold grub-common grub-pc-bin grub-pc grub2-common grub-customizer

apt update -y && sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -yq && sudo apt autoremove -y && sudo apt clean -y && sudo apt autoclean -y

sudo apt install -y htop kali-desktop-xfce

rm -r .cache .config .local

systemctl set-default graphical.target
systemctl enable lightdm
systemctl start lightdm

mv /usr/share/backgrounds/kali-16x9/default default_old
cp /usr/share/backgrounds/kali-16x9/kali-cubism.jpg /usr/share/backgrounds/kali-16x9/default

# Locate the line number of the comment "# Default: DSHELL=/bin/bash"
line_number=$(grep -n "# Default: DSHELL=/bin/bash" /etc/adduser.conf | cut -d':' -f1)

# Append "DSHELL=/bin/zsh" to the line following the comment
sed -i "$((line_number+1))iDSHELL=/bin/zsh" /etc/adduser.conf

# Create user
sudo useradd --create-home LogixBomb

# Set password
echo "LogixBomb:CupCake" | sudo chpasswd

# Create default profile
sudo mkhomedir_helper "LogixBomb"

# Add user to root group
sudo usermod -aG sudo LogixBomb

sudo apt install -y x11vnc
sudo apt install -y snapd
sudo systemctl enable snapd.apparmor
sudo systemctl enable snapd
sudo systemctl start snapd
sudo systemctl start snapd.apparmor
sudo snap install novnc
export PATH=$PATH:/snap/bin
sudo apparmor_parser -r /etc/apparmor.d/*snap-confine*
sudo apparmor_parser -r /var/lib/snapd/apparmor/profiles/snap-confine*

sudo apt update -y && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt clean -y && sudo apt autoclean -y

mkdir /home/LogixBomb/Desktop
chmod ugo+rwx /home/LogixBomb/Desktop

# Get the list of desktop directories
desktops=$(find /home -maxdepth 2 -type d -name "Desktop")
# Create the update_resolution.sh file in each desktop directory
for desktop in $desktops; do
  touch "$desktop/update_resolution.sh"
  echo '#!/bin/bash' >> "$desktop/update_resolution.sh"
  echo '' >> "$desktop/update_resolution.sh"
  echo '# Prompt the user for a screen resolution' >> "$desktop/update_resolution.sh"
  echo 'echo "Please enter your desired screen resolution in the format WIDTHxHEIGHT (e.g. 1920x1080):"' >> "$desktop/update_resolution.sh"
  echo 'read resolution' >> "$desktop/update_resolution.sh"
  echo '' >> "$desktop/update_resolution.sh"
  echo '# Find the PID for x11vnc' >> "$desktop/update_resolution.sh"
  echo 'pid=$(pgrep x11vnc)' >> "$desktop/update_resolution.sh"
  echo '' >> "$desktop/update_resolution.sh"
  echo '# Check if x11vnc is running' >> "$desktop/update_resolution.sh"
  echo 'if [ -z "$pid" ]; then' >> "$desktop/update_resolution.sh"
  echo '  echo "x11vnc is not currently running."' >> "$desktop/update_resolution.sh"
  echo 'else' >> "$desktop/update_resolution.sh"
  echo '  # Kill x11vnc' >> "$desktop/update_resolution.sh"
  echo '  kill "$pid"' >> "$desktop/update_resolution.sh"
  echo '  echo "x11vnc (PID $pid) has been terminated."' >> "$desktop/update_resolution.sh"
  echo 'fi' >> "$desktop/update_resolution.sh"
  echo '' >> "$desktop/update_resolution.sh"
  echo '# Restart the x11vnc server with the updated -geometry option' >> "$desktop/update_resolution.sh"
  echo 'x11vnc -display :0 -rfbport 5900 -nopw -bg -xkb -quiet -forever -auth guess -geometry $resolution' >> "$desktop/update_resolution.sh"
  chmod u+x "$desktop/update_resolution.sh"
done

# Add the x11vnc command to crontab
echo "@reboot x11vnc -display :0 -rfbport 5900 -nopw -bg -xkb -quiet -forever -auth guess -geometry 1280x720" >> /etc/crontab

# Add the novnc command to crontab
echo "@reboot novnc --listen 6061 --vnc localhost:5900 /snap/bin/novnc" >> /etc/crontab

# Set zsh as the default shell for new users
echo "Set zsh as the default shell for new users"
sudo sed -i 's/DSHELL=\/bin\/bash/DSHELL=\/bin\/zsh/g' /etc/adduser.conf

# Set zsh as the default shell for all existing users
echo "Set zsh as the default shell for all existing users"
for user in $(getent passwd | cut -d: -f1)
do
  sudo usermod -s /bin/zsh $user
done

echo "Done"


x11vnc -display :0 -rfbport 5900 -nopw -bg -xkb -quiet -forever -auth guess -geometry 1280x720
novnc --listen 6061 --vnc localhost:5900 /snap/bin/novnc



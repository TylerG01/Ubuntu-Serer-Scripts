#!/bin/bash

# Ubuntu Server Config
# By Tyler Gray

# This script must be run as root
# cd your/file/directory
# sudo chmod +x Ubuntu_VM_Conf.sh
# sudo ./Ubuntu_VM_Conf.sh

# When executed, this script performs the following in order
#	1). Update, Upgrades and Autoremoves any outdated packages
#	2). Detects OS then removes telementry systems by Canonical IF the system is Ubuntu
#	3). Installs and fully configures fail2ban with a 3 attempt limit before a 1 hour timeout
#   4). Installs and configures SFTP server
#	5). Adds a crontab job to automatically update & upgrade the system every morning at 5am


# Initial Update
echo "===================================================="
echo "   ===== Updating & Upgrading New Installation ==== "
echo "===================================================="
sleep 2
sudo sudo apt-get update && sudo apt-get upgrade -y
sudo apt autoremove -y


# Remove Canonical Telemetry / Spyware
echo "===================================================="
echo "     ===== Removing Canonical Telemetry  =====      "
echo "===================================================="
sleep 2
osdetect=$(uname -a)
if [[ $osdetect == *"ubuntu"* ]]; then
  sudo apt remove -y apport
  sudo apt remove -y popularity-contest
else
    echo "No modification needed."
    sleep 2
fi


# Install & configure fail2ban
echo "===================================================="
echo "     =====     Configuring fail2ban      =====      "
echo "===================================================="
sleep 2
sudo apt install fail2ban
sudo systemctl enable fail2ban
cd /etc/fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
# Changes default bantime time from 10 miunutes, to 60 minutes
sudo sed -i 's/bantime  = 10m/bantime  = 60m/' jail.local
# Changes default maximum login retries from 5 to 3 before initiating bantime seen above
sed -i 's/^maxretry = 5$/maxretry = 3/' jail.local
sudo systemctl restart fail2ban


# Install and Setup SFTP Server
echo "==================================================="
echo "      =====     Configuring SFTP Server     =====  "
echo "==================================================="
sleep 2
# Adding user and designated group
read -p "Enter desired username: " username
if [[ -z "$username" ]]; then
    echo "Error: Username cannot be empty."
    exit 1
fi
# (Optional) Ramdomly generates password for newly created user
read -p "Would you like to assign $username a randomly generated password? (y/n)" pw_response
if [["$pw_response" =~ ^[Yy]$ ]]; then
    password=$(openssl rand -base64 16)
    echo -e "$password\n$password" | sudo passwd $username
    # Displays newly created user pasword in the terminal until you press Enter
    echo "$username password has been set to: $password"
    echo "Copy the above password down, then press Enter to continue"
    read
elif [[ "$pw_response" =~ ^[Nn]$ ]]; then
    echo "no password generated. Please visit documenation to do this manually later."
    sleep 2
else
    echo "Invalid response. Please re-run script and enter 'y' or 'n'."
    sleep 2
fi
read -p "Enter desired groupname: " groupname
echo "You entered the following: "
echo "Username: $username"
echo "groupname: $groupname"
sleep 2
sudo apt install openssh-server
sudo groupadd $groupname
# -G option adds the mentioned group ‘sftp-group’ as a supplementary group to the user ‘sftp-user’. 
# -s option gives the user “/sbin/nologin” as a shell which denies interactive shell access for the user. 
sudo useradd -G $groupname -s /sbin/nologin $username
mkdir /home/$username
# Creating a Chroot jail environment for the newly created user
sudo chown root /home/$username
sudo chmod g+rx /home/$username
mkdir /home/$username/data
chown $username:$username /home/$username/data
# Creating a directory called '.ssh' inside the newly created user's home directory, then makes the user the owner.
mkdir /home/$username/.ssh
sudo chown $username:$username /home/$username/.ssh
sudo chmod 700 /home/$username/.ssh
# Creating authorized_keys file if it does not exist
ssh_dir="/home/$username/.ssh"
authorized_keys_file="$ssh_dir/authorized_keys"
if [ ! -f "$authorized_keys_file" ]; then
    touch "$authorized_keys_file"
    chmod 600 "$authorized_keys_file"
fi
# Change OpenSSH Config File
config_block="
Match group $groupname
ChrootDirectory /home/%u
ForceCommand internal-sftp
AllowTcpForwarding no
PasswordAuthentication no
X11Forwarding no
PermitRootLogin no
RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeyFile	.ssh/authorized_keys
ChallengeResponseAuthenticaiton no
UsePAM yes
"
# Append the configuration block to /etc/ssh/sshd_config
echo "$config_block" >> /etc/ssh/sshd_config
# Configure SFTP subsystem to use 'initernal-sftp'
sed -i 's|Subsystem[[:space:]]\+sftp[[:space:]]\+usr/lib/openssh/sftp-server|Subsystem    sftp    internal-sftp|' /etc/ssh/sshd_config
# Restart SSH service for edits to take effect
sudo systemctl restart sshd
echo "==================================================="
echo "    =====     SFTP Server Conf Complete   =====    "
echo "==================================================="
sleep 2


# Add a cron job to update and upgrade the system every morning at 5 AM
(crontab -l 2>/dev/null; echo "0 5 * * * apt update && apt upgrade -y") | crontab -
echo "======================================================================"
echo "Cron job added to update and upgrade the system every morning at 5 AM "
echo "======================================================================"
sleep 2


#Closing Message
echo "===================================================="
echo "    ===== System Configured: Have a Great Day ===== "
echo "===================================================="

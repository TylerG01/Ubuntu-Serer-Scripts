#!/bin/bash

# Adding user and designated group
read -p "Enter desired username: " username
if [[ -z "$username" ]]; then
    echo "Error: Username cannot be empty."
    exit 1
fi
# (Optional) Ramdomly generates password for newly created user
read -p "Would you like to assign $username a randomly generated password? (y/n):" pw_response
if [[ "$pw_response" =~ ^[Yy]$ ]]; then
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
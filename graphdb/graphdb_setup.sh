#!/usr/bin/bash
# Script to install graphdb ver 9 on a nector instance
# See recommandation: http://graphdb.ontotext.com/documentation/free/requirements.html

#1. Spin up a nectar instance
#2. ssh to it and run this script.
#==================================

# 1. Update this instance
sudo apt-get update

# 2. Install some useful tools
sudo apt-get -y install vim tmux htop unzip

# 3. Install jdk 12
#   Installing Oracle JDK 12 using PPA
#   Press <ENTER> to continue
sudo add-apt-repository ppa:linuxuprising/java

# Now, install Oracle JDK 12
#   On popup select <OK> and <YES>
sudo apt install -y oracle-java12-installer

#Java 12 should be installed now
java -version 

# 4. Installing ZFS
#    Install the user-level tools
sudo apt install -y zfsutils-linux

#    In addition to be able to have ZFS on root, install
sudo apt install zfs-initramfs 

# 5. Very important - before zpool create
umount /dev/vdb

# Create zfs pool on data
zpool create -f data /dev/vdb
chmod a+rwx /data
#Uncomment below line if you have setup additional volume on Nectar for this instance
#zpool add -f data /dev/vdc

# Link mnt directory to data zfs pool folder
cd /
rm -R mnt
ln -s data/ mnt
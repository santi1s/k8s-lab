#!/bin/bash

## partition, format and mount additional storage
# create msdos table and primary partition
DISK=$(sudo lsblk | grep -m1 128G | awk '{print $1}')
sudo parted --script /dev/$DISK \
    mklabel msdos \
    mkpart primary ext4 1MiB 100%
sudo partprobe
# format primary partition with ext4	
sudo mkfs.ext4 /dev/${DISK}1

## install required packages
sudo apt update; sudo apt install qemu qemu-kvm libvirt-bin bridge-utils virt-manager -y

# persistently mount the new partition in /virt
sudo mkdir /virt
DISK_UUID=$(ls -l /dev/disk/by-uuid | grep ${DISK}1 | awk '{print $9}')
echo "UUID=${DISK_UUID} /virt ext4 defaults 0 2" | sudo tee -a /etc/fstab
sudo mount -a

# download and set the build-vm script and ubuntu 16.04 cloud image
sudo wget https://raw.githubusercontent.com/sturrent/kvm-build-with-cloud-image/master/build-vm.sh -O /virt/build-vm.sh
sudo chmod u+x /virt/build-vm.sh

# download ubuntu 18.04 cloud image
sudo mkdir /virt/images
sudo wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img -O /virt/images/bionic-server-cloudimg-amd64.img

# resize the cloud image to 40G
sudo qemu-img resize /virt/images/bionic-server-cloudimg-amd64.img 40G

# create an ssh key if you don't have one already
ssh-keygen -N "" -f ~/.ssh/id_rsa

#!/bin/bash


## partition, format and mount additional storage
# create msdos table and primary partition
{ # try
    disk=$(lsblk | grep -m1 128G | awk '{print $1}')
    if test -n "${disk-}"; then
        #part=$(lsblk | grep -m1 "${disk}1" | awk '{print $1}')
        #if ! test -n "${part}";then
            parted --script /dev/$disk mklabel msdos mkpart primary ext4 1MiB 100%
            partprobe
            sleep 1
            # format primary partition with ext4	
            mkfs.ext4 /dev/${disk}1 -e continue
       # fi
    else
        echo -e  "disk is not set or empty"
        exit 1
    fi
} || { # catch
    echo -e "Unexpected error while creating partioned disk for kvm!"
    exit 1
}

## install required packages
{ # try
    apt update; sudo apt install qemu qemu-kvm libvirt-bin bridge-utils virt-manager -y
} || { # catch
    echo -e "Unexpected  error while installing packages!"
    exit 1
}

# persistently mount the new partition in /virt
{ # try
    mkdir /virt
    disk_uuid=$(ls -l /dev/disk/by-uuid | grep ${disk}1 | awk '{print $9}')
    if test -n "${disk_uuid-}"; then
        echo "UUID=${disk_uuid} /virt ext4 defaults 0 2" | sudo tee -a /etc/fstab
        mount -a
    else
        echo -e  "Could not find disk uuid to mount in /virt"
        exit 1
    fi
} || { # catch
    echo -e "Unexpected error while creating persistent mount for /virt"
    exit 1
}

# download and set the build-vm script and ubuntu 16.04 cloud image
{ # try
    wget https://raw.githubusercontent.com/santi1s/k8s-lab/main/tools/build_vm.sh -O /virt/build-vm.sh
    chmod u+x /virt/build-vm.sh
} || { # catch
    echo -e "Unexpected Unexpected error downloading build-vm script"
    exit 1
}

# download ubuntu 18.04 cloud image
{ # try
    mkdir /virt/images
    wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img -O /virt/images/bionic-server-cloudimg-amd64.img
} || { # catch
    echo -e "Unexpected Unexpected error downloading ubuntu 18.04 cloud image"
    exit 1
}

# resize the cloud image to 40G
{ # try
    qemu-img resize /virt/images/bionic-server-cloudimg-amd64.img 40G
} || { # catch
    echo -e "Unexpected error resizing cloud image to 40G"
    exit 1
}

# create an ssh key for azureuser
{ # try
    sudo -H -u azureuser bash -c 'ssh-keygen -N "" -f ~/.ssh/id_rsa'
} || { # catch
    echo -e "Unexpected error creating ssh key for azure user"
    exit 1
}


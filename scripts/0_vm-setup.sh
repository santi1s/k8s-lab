#!/bin/bash

## Prerequisites

#check user
if [[ $EUID -ne 0 ]]; then
   echo -e "This script must be run as root\n" 
   exit 1
fi

#check bash version
version=$(bash --version | grep "^GNU bash" | awk '{print $4}' | awk -F "." '{print $1}')
if [ $version -lt 4 ]; then
    echo -e "This script requires bash version > 4\n"
    exit 1
fi

# Scripts to execute

bash_scripts=("./kvm/0_kvm-setup.sh" "./docker/1_docker-setup.sh")

#iterate scripts array and execute them
for script in ${bash_scripts[@]}; do
{
    { # try
        ( test -f $script ) && bash "$script"
    } || { # catch
        echo -e "$script not found or error in $script execution"
        exit 1
    }
}
done

exit 0
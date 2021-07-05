#!/bin/bash

# Deploy k8s lab VMs (one master and two worker nodes)


{ # try
    # deploy masternode1
    bash /virt/build-vm.sh -n masternode1 -c 2 -m 2048 -s /home/azureuser/.ssh/id_rsa.pub
    # deploy workernode1
    bash /virt/build-vm.sh -n workernode1 -c 2 -m 2048 -s /home/azureuser/.ssh/id_rsa.pub
    # deploy workernode2
    bash /virt/build-vm.sh -n workernode2 -c 2 -m 2048 -s /home/azureuser/.ssh/id_rsa.pub
} || { # catch
    echo -e "Unexpected error while deploying k8s Lab VMs "
    exit 1
}


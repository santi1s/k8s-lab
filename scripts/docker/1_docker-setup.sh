#!/bin/bash

# Script to setup Docker CE and kubectl installed.

# install dependencies
{ # try
    apt update
    apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
} || { # catch
    echo -e "Unexpected error while installing package dependencies"
    exit 1
}

# get the Docker gpg key
{ # try
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
} || { # catch
    echo -e "Unexpected error while downloading Docker gpg key "
    exit 1
}

# add the Docker repository
{ # try
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" 
} || { # catch
    echo -e "Unexpected error while adding Docker repository"
    exit 1
}

# get the Kubernetes gpg key
{ # try
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
} || { # catch
    echo -e "Unexpected error while downloading google gpg key"
    exit 1
}


# add the Kubernetes repository
{ # try
    echo "deb https://apt.kubernetes.io/  kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
} || { # catch
    echo -e "Unexpected error while adding Kubernetes repository"
    exit 1
}


# update and install packages
{ # try
    apt update && apt install docker-ce=5:20.10.7~3-0~ubuntu-bionic docker-ce-cli=5:20.10.7~3-0~ubuntu-bionic containerd.io kubectl=1.19.12-00 -y
} || { # catch
    echo -e "Unexpected error installing packages for kubectl"
    exit 1
}


# hold them at the current version
{ # try
    apt-mark hold docker-ce kubectl docker-ce-cli
} || { # catch
    echo -e "Unexpected error installing holding docker/kubectl packages"
    exit 1
}

#add azureuser to docker group
{ # try
    usermod -aG docker azureuser
} || { # catch
    echo -e "Unexpected error adding azureuser to docker group"
    exit 1
}


#!/bin/bash

ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP.log"

#eksctl variables
#=================
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

echo "script started executing at $TIMESTAMP" &>> $LOGFILE

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILED $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

if [ $ID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N"
    exit 1 # you can give other than 0
else
    echo "You are root user"
fi # fi means reverse of if, indicating condition end

#Installing Docker
#====================================================================
dnf -y install dnf-plugins-core
VALIDATE $? "Installed dnf-plugin-core"

dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
VALIDATE $? "Added docker repo"

dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
VALIDATE $? "Installed docker components"

systemctl enable --now docker
VALIDATE $? "Enabled and Started docker"

usermod -aG docker ec2-user
VALIDATE $? "added ec2-user to docker group"

echo -e "$R Logout and login again $N"

#Installing Kubectl
#====================================================================

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl

mv kubectl /usr/local/bin/kubectl

VALIDATE $? "Installing Kubectl"

#Installing eksctl
#====================================================================

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"

tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz

sudo install -m 0755 /tmp/eksctl /usr/local/bin && rm /tmp/eksctl

VALIDATE $? "Installing eksctl"

git clone https://github.com/ahmetb/kubectx /opt/kubectx

ln -s /opt/kubectx/kubens /usr/local/bin/kubens

VALIDATE $? "Installing kubens"

# Installing Helm 
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

VALIDATE $? "Installing Helm"


# # Installing K9s
# curl -sS https://webinstall.dev/k9s | bash
# VALIDATE $? "Installing K9s"

git clone https://github.com/devopsprocloud/k8-eksctl.git 
VALIDATE $? "cloning k8-eksctl repo"

cd /home/ec2-user/k8-eksctl
VALIDATE $? "Go to '/k8-eksctl' directory" &>> $LOGFILE

eksctl create cluster --config-file=eks.yaml 
VALIDATE $? "Installing ekscluster"

helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm upgrade --install aws-ebs-csi-driver \
    --namespace kube-system \
    aws-ebs-csi-driver/aws-ebs-csi-driver

VALIDATE $? "Installing EBS CSI Driver"
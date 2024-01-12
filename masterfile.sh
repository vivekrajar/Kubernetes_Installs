#!/bin/bash

install_ubuntu() {
   #### containerd installation starts 
   which containerd
   if [ $? -eq 0 ];then
      systemctl stop containerd.service
      apt-get remove -y containerd
      apt-get purge -y containerd
      apt -y autoremove
      if [ -f /etc/modules-load.d/containerd.conf ];then
         rm /etc/modules-load.d/containerd.conf
      fi
      if [ -f /etc/sysctl.d/99-kubernetes-cri.conf ];then
         rm /etc/sysctl.d/99-kubernetes-cri.conf
      fi
      if [ -f /etc/containerd/config.toml ];then
         rm /etc/containerd/config.toml
      fi
   else
      echo "containerd is not installed.. continue to install"
   fi
   ## Install using the repository:
   apt-get update
   apt-get install -y containerd
   if [ $? -eq 0 ];then
       echo "containerd is successfully installed"
       configure_contd
   else
     echo "issue with containerd installation - process abort"
     exit 1
   fi
   # exit 0   
   #### containerd installation ends    
   #### Install Kubernetes latest components
   sudo rm -rf /etc/apt/sources.list.d/kubernetes.list
   sudo apt-get update
   sudo apt-get install -y apt-transport-https ca-certificates curl gpg
   echo "starting the installation of k8s components (kubeadm,kubelet,kubectl) ...."
   sudo mkdir /etc/apt/keyrings/
   curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
   echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
   echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
   echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
   echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.26/deb/ /" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
   echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.25/deb/ /" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
   echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.24/deb/ /" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
   sudo apt-get update
   sudo apt-get install -y kubelet kubeadm kubectl

   if [ $? -eq 0 ];then
      echo "kubelet, kubeadm & kubectl are successfully installed"
      sudo apt-mark hold kubelet kubeadm kubectl
   else
      echo "issue in installing kubelet, kubeadm & kubectl - process abort"
      exit 2
   fi

   ## Initialize kubernetes Master Node 
   sudo kubeadm init --ignore-preflight-errors=all
   sudo mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config

   ## below installs calico networking driver

   kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/calico.yaml

   ## Verify

   kubectl get nodes

}

install_centos() {

echo "Nothing here"

}

install_amzn() {

echo "Nothing here"

}
################ MAIN ###################

if [ -f /etc/os-release ];then
   osname=`grep ID /etc/os-release | egrep -v 'VERSION|LIKE|VARIANT|PLATFORM' | cut -d'=' -f2 | sed -e 's/"//' -e 's/"//'`
   echo $osname
   if [ $osname == "ubuntu" ];then
       install_ubuntu
   elif [ $osname == "amzn" ];then
       install_amzn
   elif [ $osname == "centos" ];then
       install_centos
  fi
else
   echo "can not locate /etc/os-release - unable find the osname"
   exit 8
fi
exit 0
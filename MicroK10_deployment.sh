#!/bin/bash
###############################
#Name: MicroK10_deployment.sh
#Author: Adam Bergh
#Date: 07/07/2021 v1
#Kasten by Veeam
#Version: 1.0
################################

# COLOR CONSTANTS
GREEN='\033[0;32m'
LIGHT_BLUE='\033[1;34m'
RED='\033[0;31m'
NC='\033[0m'

#GLOBAL VARIABLES
IP_1=""
IP_2=""

trap ctrl_c INT

function ctrl_c() {

	printf "${NC}Canceling Job!\n"
	killall MicroK10_deployment.sh
	exit 1

}

menuFunction() {
   clear
   printf "${GREEN}----------------------------------------------------\n"
   printf "${GREEN}Welcome to the Micro Kasten K10 deployment Appliance\n"
   printf "${GREEN}This Appliance will deploy an all-in-one K8s cluster\n"
   printf "${GREEN}with Kasten K10 and a test application\n"
   printf "${GREEN}-----------------------------------------------------\n"
   printf "\n"
   printf "Would you like to start the deployment? This will take about 10 minutes:\n"
   read -p "Press [Enter] key to start, otherwise hit ctrl+c..."
   printf "${NC}Starting deployment at $(date +%y/%m/%d) at $(date +%H:%M:%S). Please Wait....\n"
}

setIPAddress() {
   clear
   printf "${GREEN}---------------------------------------------------------------------\n"
   printf "${GREEN}This appliance will need two static IP addresses with internet access\n"
   printf "${GREEN}---------------------------------------------------------------------\n"
   printf "\n"
   printf "${LIGHT_BLUE}Enter IP that will be use for the appliance's IP in format xxx.xxx.xxx.xxx\n"
   printf "${NC}\n"
   read IP_1
   printf "\n"
#   printf "${LIGHT_BLUE}Enter a range of three or more consecutive IP addresses in the following format xxx.xxx.xxx.xxx-xxx.xxx.xxx.xxx\n"
#   printf "${LIGHT_BLUE}These will be used for applications deployed on the K8s Cluster\n"
#   printf "${NC}\n"
#   read IP_2
#   printf "\n"
   printf "${LIGHT_BLUE}Enter subnet mask in slash notation, example /24 or /23:\n"
   printf "${NC}\n"
   read SUBNET
   printf "\n"
   printf "${LIGHT_BLUE}Enter gateway IP in the following format xxx.xxx.xxx.xxx\n"
   printf "${NC}\n"
   read GATEWAY
   printf "\n"
   printf "${GREEN}You've Entered:\n"
   printf "${GREEN}IP Address 1: $IP_1\n"
   printf "${GREEN}IP Address Range is: $IP_2\n"
   printf "${GREEN}Subnet Mask: $SUBNET\n"
   printf "${GREEN}Gateway: $GATEWAY\n"
   printf "${GREEN}Is This Correct?\n"
   printf "${NC}\n"
   read -p "Press [Enter] key if correct, otherwise hit ctrl+c..."
   cat <<EOF> /etc/netplan/50-cloud-init.yaml
   network:
       ethernets:
           ens160:
               dhcp4: no
               addresses:
                 - ${IP_1}${SUBNET}
               gateway4: ${GATEWAY}
               nameservers:
                   addresses: [1.1.1.1]
EOF

   netplan apply
   current_ip=$(ip addr show ens192 | grep "inet\b" | awk '{print $2}')
   printf "${NC}Your current ip address is $current_ip\n"

   wget -q --spider http://google.com
   if [ $? -eq 0 ]; then
    echo "You are Online"
   else
    echo "Cannot Reach Internet, Please re-check your settings"
	exit 1
   fi


}

deployMicroK8S() {
printf "${GREEN}Deploying MicroK8s\n"
snap install microk8s --classic
sleep 1m
microk8s enable dns registry istio helm3
sleep 2m
#microk8s enable metallb:${IP_2}
#sleep 30
}


deployWordpress() {
microk8s helm3 repo add bitnami https://charts.bitnami.com/bitnami
microk8s kubectl create namespace wordpress
microk8s helm3 install wordpress --namespace wordpress \
  --set wordpressUsername=admin \
  --set wordpressPassword=password \
  --set mariadb.auth.rootPassword=secretpassword \
    bitnami/wordpress
	sleep 2m
}



deployK10 () {
	microk8s helm3 repo add kasten https://charts.kasten.io/
	microk8s kubectl create namespace kasten-io
	microk8s helm3 install k10 kasten/k10 --namespace=kasten-io \
	--set injectKanisterSidecar.enabled=true \
	--set auth.basicAuth.enabled=true \
	--set auth.basicAuth.htpasswd='admin:{SHA}w897J5HmKpAlulJ694w+DvVjSp8='
	echo "Waiting for K10 to finished starting"
	sleep 4m
	#kasten_ip=$(microk8s kubectl get svc gateway-ext --namespace kasten-io -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
	echo ""
	microk8s kubectl --namespace kasten-io port-forward service/gateway 8080:8000 --address ${IP_1}  > /dev/null 2>&1 &
	echo "DONE! You should be able to access K10 at http://${IP_1}:8080/k10/#"
	exit 1
}


#Call Functions Here

menuFunction
setIPAddress
deployMicroK8S
deployWordpress
deployK10

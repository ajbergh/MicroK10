#!/bin/bash
###############################
#Name: MicroK10_deployment menu.sh
#Author: Adam Bergh
#Date: 07/07/2021 v1
#Kasten by Veeam
#Version: .1 Alpha
################################

# COLOR CONSTANTS
GREEN='\033[0;32m'
LIGHT_BLUE='\033[1;34m'
RED='\033[0;31m'
NC='\033[0m'
RED_BG="\[\033[41m\]"         # Red background
GREEN_BG="\[\033[42m\]"       # Green background


setIPAddress() {
   clear
  # printf "${GREEN}=====================================================================\n"
  # printf "${GREEN}This appliance will need two static IP addresses with internet access\n"
   #printf "${GREEN}=====================================================================\n"
  # printf "\n"
   printf "${GREEN}Enter IP that will be use for the appliance's IP in format xxx.xxx.xxx.xxx\n"
   printf "${NC}\n"
   read IP_1
   printf "\n"
   printf "${GREEN}Enter a range of three or more consecutive IP addresses in the following format xxx.xxx.xxx.xxx-xxx.xxx.xxx.xxx\n"
   printf "${GREEN}These will be used for applications deployed on the K8s Cluster\n"
   printf "${NC}\n"
   read IP_2
   printf "\n"
   printf "${GREEN}Enter subnet mask in slash notation, example /24 or /23:\n"
   printf "${NC}\n"
   read SUBNET
   printf "\n"
   printf "${GREEN}Enter gateway IP in the following format xxx.xxx.xxx.xxx\n"
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
           ens192:
               dhcp4: no
               addresses:
                 - ${IP_1}${SUBNET}
               gateway4: ${GATEWAY}
               nameservers:
                   addresses: [1.1.1.1]
EOF

   netplan apply
   #current_ip=$(ip addr show ens192 | grep "inet\b" | awk '{print $2}')
   #printf "${NC}Your current ip address is $current_ip\n"

}

K8s_Install() {

echo "Deploying K8s. Please Wait"
echo ""
/root/deployMicroK8S.sh $IP_2 &>/dev/null & disown


while ps ax | grep -v grep | grep "deployMicroK8S.sh" > /dev/null
do
    echo -n .
    sleep 2
done

echo ""
echo "Deploying Kasten K10. Please Wait"
echo ""

/root/deployK10.sh >/dev/null &>/dev/null & disown

while ps ax | grep -v grep | grep "deployK10.sh" > /dev/null
do
    echo -n .
    sleep 2
done

echo ""
echo "Deploying Wordpress on K8s. Please Wait"
echo ""

/root/deployWordpress.sh >/dev/null &>/dev/null & disown

while ps ax | grep -v grep | grep "deployWordpress.sh" > /dev/null
do
    echo -n .
    sleep 2
done



}


setIPAddress

sleep 5
#K8s_Install

wget -q --spider http://google.com
   if [ $? -eq 0 ]; then
    echo "You are Online. Starting Install"
	K8s_Install
   else
    echo "Cannot Reach Internet, Please re-run IP Address setup"
	read -p "Press [Enter] key to re-start IP setup..."
	setIPAddress
   fi


kasten_ip=$(microk8s kubectl get svc gateway-ext --namespace kasten-io -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
	echo ""
	echo "DONE! You should be able to access K10 at http://${kasten_ip}/k10/#"
	sleep 5
	/root/menu.sh

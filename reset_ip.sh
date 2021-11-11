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


askIPAddress() {

	printf "${GREEN}Use DHCP or Set Static IP?\n" 
    #printf "${GREEN}Press 1 for DHCP. Press 2 for Static.\n"
	printf "${GREEN}1) Set Static IP Address\n"
	printf "${GREEN}2) Set DHCP\n"
	printf "${NC}\n"
	read answer  # create variable to retains the answer
	case "$answer" in
        1) setStatic ;;
        2) setDHCP ;;
    esac


}


setDHCP() {
	printf "${GREEN}Setting DHCP\n"
	sleep 2
	cat <<EOF> /etc/netplan/50-cloud-init.yaml
network:
       ethernets:
           ens160:
               dhcp4: yes
EOF

   netplan apply
   sleep 5
   current_ip=$(ifconfig ens160 | grep 'netmask' | cut -d: -f2 | awk '{print $2}')
   printf "${NC}Your current ip address is now: $current_ip\n"


}



setStatic() {
   clear
  # printf "${GREEN}=====================================================================\n"
  # printf "${GREEN}This appliance will need two static IP addresses with internet access\n"
   #printf "${GREEN}=====================================================================\n"
  # printf "\n"
   printf "${GREEN}Enter IP that will be use for the appliance's IP in format xxx.xxx.xxx.xxx\n"
   printf "${NC}\n"
   read IP_1
   printf "\n"
  #printf "${GREEN}Enter a range of three or more consecutive IP addresses in the following format xxx.xxx.xxx.xxx-xxx.xxx.xxx.xxx\n"
   #printf "${GREEN}These will be used for applications deployed on the K8s Cluster\n"
   #printf "${NC}\n"
   #read IP_2
  # printf "\n"
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
   #printf "${GREEN}IP Address Range is: $IP_2\n"
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
   sleep 5
   current_ip=$(ifconfig ens160 | grep 'netmask' | cut -d: -f2 | awk '{print $2}')
   printf "${NC}Your current ip address is now: $current_ip\n"

}




askIPAddress

sleep 5


	echo ""
	#echo "DONE! You should be able to access K10 at http://${kasten_ip}/k10/#"
	sleep 5
	/root/menu.sh

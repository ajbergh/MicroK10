#!/bin/bash
###############################
#Name: reset_ip_addresses.sh
#Author: Adam Bergh
#Date: 07/07/2021 v1
#Kasten by Veeam
#Version: .1 Alpha
################################


setIPAddress() {
   clear
  # printf "${GREEN}=====================================================================\n"
  # printf "${GREEN}This appliance will need two static IP addresses with internet access\n"
   #printf "${GREEN}=====================================================================\n"
  # printf "\n"
   printf "${LIGHT_BLUE}Enter IP that will be use for the appliance's IP in format xxx.xxx.xxx.xxx\n"
   printf "${NC}\n"
   read IP_1
   printf "\n"
   printf "${LIGHT_BLUE}Enter a range of three or more consecutive IP addresses in the following format xxx.xxx.xxx.xxx-xxx.xxx.xxx.xxx\n"
   printf "${LIGHT_BLUE}These will be used for applications deployed on the K8s Cluster\n"
   printf "${NC}\n"
   read IP_2
   printf "\n"
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
           ens192:
               dhcp4: no
               addresses:
                 - ${IP_1}${SUBNET}
               gateway4: ${GATEWAY}
               nameservers:
                   addresses: [1.1.1.1]
EOF

   netplan apply
   
   cat <<EOF> metallb-config.yaml
     apiVersion: v1
     kind: ConfigMap
     metadata:
     namespace: metallb-system
     name: config
     data:
     config: |
     	address-pools:
     	- name: default
     	protocol: layer2
     	addresses:
     	- ${IP_2}
EOF
   
   microk8s kubectl apply -f metallb-config.yaml
   #current_ip=$(ip addr show ens192 | grep "inet\b" | awk '{print $2}')
   #printf "${NC}Your current ip address is $current_ip\n"

}

setIPAddress
echo "IP Addresses Reset"
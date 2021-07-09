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


trap '' 2  # ignore control + c
while true
do
   clear
   printf "${LIGHT_BLUE}=========================================================\n"
   printf "${NC}Welcome to the Veeam Ready  Kasten K10  Appliance\n"
   printf "${NC}This Appliance will deploy an all-in-one K8s cluster\n"
   printf "${NC}with Kasten K10 and a test application\n"
   printf "${NC}Please follow all instructions when using this appliance.\n"
   printf "${LIGHT_BLUE}=========================================================\n"
   printf "\n"
   
   if ! which microk8s > /dev/null; then
      printf  "${NC}Current Status of Appliance is ${RED}NOT INSTALLED\n"
	  printf "${NC}\n"
	  printf "${GREEN}Would you like to start the deployment?\n" 
      printf "${GREEN}Press 1 and hit enter. This will take about 10 minutes:\n"
      read answer  # create variable to retains the answer
      case "$answer" in
        1) /root/start_install.sh ;;
        e) exit ;;
      esac
      echo -e "Hit the <return> key to continue..."
      read input ##This cause a pause so we can read the output of the selection before the loop clear the screen
   else
      printf  "${NC}Current Status of Appliance is ${GREEN}INSTALLED\n"
	  printf "${NC}\n"
	  kasten_ip=$(microk8s kubectl get svc gateway-ext --namespace kasten-io -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
	  printf "${NC}Your Kasten K10 is reachable at ${GREEN}http://${kasten_ip}/k10/#\n"
	  printf "${NC}Kasten K10 credentials are admin/Veeam123!\n"
	  printf "\n"
	  wordpress_ip=$(microk8s kubectl get svc wordpress --namespace wordpress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
	  printf "${NC}Your Wordpress installations is reachable at ${GREEN}http://${wordpress_ip}/${NC}\n"
	  printf "\n"
	  printf "${NC}Option 1: Delete Wordpress. Do this after a successfull backup by K10:\n"
	  printf "${NC}Option 2: Re-run IP Address setup script. Re-run if you are not getting and IP for K10.\n"
      read answer  # create variable to retains the answer
      case "$answer" in
        1) /root/delete_wordpress.sh ;;
		2) /root/reset_ip_addresses.sh ;;
        e) exit ;;
      esac
      echo -e "Hit the <return> key to continue..."
      read input ##This cause a pause so we can read the output of the selection before the loop clear the screen
 	  
   fi
done
   
   
   
   
  

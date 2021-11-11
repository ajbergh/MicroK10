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


#FUNCTIONS ##########################################################################################################

#IP Address Selection Function when first booting
askIPAddress() {
	choices=('Keep Current IP Configuration' 'Set Static IP Address' 'Set DHCP')
	printf "${GREEN}Choose: Keep Current IP or Set New Static IP or set interface to DHCP:\n"
	PS3="Make a selection:"
	select choice in "${choices[@]}"; do
		case $choice in
			"${choices[0]}")
				keepCurrentIP 
				break;;
			"${choices[1]}")
				setStatic 
				break;;
			"${choices[2]}")
				setDHCP 
				break ;;
			*) printf "${RED}INVALID SELECTION\n"
			printf "${GREEN}\n";;
		esac
	done
}

#IP Address Selection when re-running IP address setup
askIPAddress2(){

	choices=('Keep Current IP Configuration' 'Set Static IP Address' 'Set DHCP' 'Cancel')
	printf "${GREEN}Choose: Keep Current IP or Set New Static IP or set interface to DHCP:\n"
	PS3="Make a selection:"
	select choice in "${choices[@]}"; do
		case $choice in
			"${choices[0]}")
				keepCurrentIP 
				break;;
			"${choices[1]}")
				setStatic 
				break;;
			"${choices[2]}")
				setDHCP 
				break ;;
			"${choices[3]}") 
			clear
				break ;;
			*) printf "${RED}INVALID SELECTION\n"
			printf "${GREEN}\n";;
		esac
	done
	sleep 5
	  current_ip=$(ifconfig ens160 | grep 'netmask' | cut -d: -f2 | awk '{print $2}')
	resetPortForward
}


#Print Current IP Address Function
printCurrentIP(){
current_ip=$(ip addr list ens160 | grep ens160 | grep inet | awk '{print $2}')
current_gateway=$(ip r | grep ens160 | grep default | awk '{print $3}')
current_dns=$(systemd-resolve --status | sed -n '/DNS Servers/,/^$/p' | awk '{print $3}')
printf "${GREEN}Your Current IP Address Settings Are:\n"
printf "\n"
printf "${GREEN}IP Address: ${current_ip}\n"
printf "${GREEN}Gateway: ${current_gateway}\n"
printf "${GREEN}DNS: ${current_dns}\n"
printf "\n"
}

#Set interface to DHCP Function
setDHCP() {
	
	killall -9 kubectl > /dev/null 2>&1 & #stop any kubectl port-forward commands running in memory
	printf "${GREEN}Setting DHCP\n"
	sleep 2
	cat <<EOF> /etc/netplan/50-cloud-init.yaml
network:
       ethernets:
           ens160:
               dhcp4: yes
EOF

   netplan apply
   sleep 1
   current_ip=$(ifconfig ens160 | grep 'netmask' | cut -d: -f2 | awk '{print $2}')
   printf "${NC}Your current ip address is now: $current_ip\n"
   sleep 3
}

#Set Interface to Static IP Function
setStatic() {
   clear

   killall -9 kubectl > /dev/null 2>&1 & #stop any kubectl port-forward commands running in memory
   
   valid_ip=0
    
   while [ $valid_ip -le 0 ]
   do
		printf "${GREEN}Enter IP that will be used for the appliance's IP in format xxx.xxx.xxx.xxx\n"
		printf "${NC}\n"
		read IP_1
	   if [[ "$IP_1" =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; then
			#echo "Valid IP: $ip";
			((valid_ip++))
	   else
			printf "${RED}Invalid IP: $IP_1";
			printf "${NC}\n"
	   fi
   done
   
   
   
   printf "\n"
   

	valid_subnet=0
	while [ $valid_subnet -le 0 ]
	do
		printf "${GREEN}Enter subnet mask in CIDR notation, example /24 or /23:\n"
		printf "${NC}\n"
		read SUBNET
		printf "\n"
	
	
	if [[ "$SUBNET" =~ /[0-9]{1,2}$ ]]; then
		#echo "Valid CIDR: $cidr";
		((valid_subnet++))
	else
		printf "${RED}Invalid CIDR Subnet: $SUBNET";
		printf "${NC}\n"
	fi
	done



   
   valid_gateway=0
   
   while [ $valid_gateway -le 0 ]
   do
		printf "${GREEN}Enter gateway IP in the following format xxx.xxx.xxx.xxx\n"
		printf "${NC}\n"
		read GATEWAY
	   if [[ "$GATEWAY" =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; then
			#echo "Valid IP: $ip";
			((valid_gateway++))
	   else
			printf "${RED}Invalid Gateway IP: $GATEWAY";
			printf "${NC}\n"
	   fi
   done
   
   printf "\n"
   printf "${GREEN}You've Entered:\n"
   printf "${GREEN}IP Address 1: $IP_1\n"
   printf "${GREEN}Subnet Mask: $SUBNET\n"
   printf "${GREEN}Gateway: $GATEWAY\n"
   printf "${GREEN}Is This Correct?\n"
   printf "${NC}\n"
   
  choices=('Apply' 'Cancel')
	printf "${GREEN}Apply or Cancel?\n"
	PS3="Make a selection:"
	select choice in "${choices[@]}"; do
		case $choice in
			"${choices[0]}")
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

   sleep 1
   printf "${NC}Setting Static IP Address. Please wait....\n"
   netplan apply
   sleep 3
   current_ip=$(ifconfig ens160 | grep 'netmask' | cut -d: -f2 | awk '{print $2}')
   printf "${NC}Your static ip address is now: $current_ip\n"
   sleep 3
   microk8s kubectl --namespace kasten-io port-forward service/gateway 8080:8000 --address ${current_ip}  > /dev/null 2>&1 &
   microk8s kubectl --namespace wordpress port-forward service/wordpress 8081:80 --address ${current_ip}  > /dev/null 2>&1 & 
				break;;
			"${choices[1]}")
				break;;
			*) printf "${RED}INVALID SELECTION\n"
			printf "${GREEN}\n";;
		esac
	done
   
   

}

#Function to detect current IP and re-apply it
keepCurrentIP() {

killall -9 kubectl > /dev/null 2>&1 & #stop any kubectl port-forward commands running in memory

IP_1=$(ip addr list ens160 | grep ens160 | grep inet | awk '{print $2}')
GATEWAY=$(ip r | grep ens160 | grep default | awk '{print $3}')
current_dns=$(systemd-resolve --status | sed -n '/DNS Servers/,/^$/p' | awk '{print $3}')

cat <<EOF> /etc/netplan/50-cloud-init.yaml
   network:
       ethernets:
           ens160:
               dhcp4: no
               addresses:
                 - ${IP_1}
               gateway4: ${GATEWAY}
               nameservers:
                   addresses: [1.1.1.1]
EOF

   netplan apply
   sleep 5
   current_ip=$(ifconfig ens160 | grep 'netmask' | cut -d: -f2 | awk '{print $2}')
   printf "${NC}Your current ip address is: $current_ip\n"


}

#Print Menu Banner
printBanner(){
   printf "${LIGHT_BLUE}=========================================================\n"
   printf "${NC}Welcome to the Kasten K10 Appliance\n"
   printf "${NC}This Appliance will deploy an all-in-one K8s cluster\n"
   printf "${NC}with Kasten K10 and a test application\n"
   printf "${NC}Please follow all instructions when using this appliance.\n"
   printf "${LIGHT_BLUE}=========================================================\n"
   printf "\n"

}

#Function to check in MicroK8s is installed
checkMicroK8s(){
   if ! which microk8s > /dev/null; then
      printf  "${NC}Current Status of Appliance is ${RED}NOT INSTALLED\n"
	  printf "${NC}\n"
	  printf "${GREEN}Would you like to start an online deployment? (Requires Internet)\n"    
	choices=('Start Install')
	printf "${GREEN}Press 1 to start appliance install. This will take about 10 minutes:\n"
	PS3="Make a selection:"
	select choice in "${choices[@]}"; do
		case $choice in
			"${choices[0]}")
				startNewInstall 
				break;;
			*) printf "${RED}INVALID SELECTION\n"
			printf "${GREEN}\n";;
		esac
	done
   ./setup_minio.sh > /dev/null 2>&1 &
   current_ip=$(ifconfig ens160 | grep 'netmask' | cut -d: -f2 | awk '{print $2}')
	  microk8s kubectl --namespace kasten-io port-forward service/gateway 8080:8000 --address ${current_ip}  > /dev/null 2>&1 &

	  microk8s kubectl --namespace wordpress port-forward service/wordpress 8081:80 --address ${current_ip}  > /dev/null 2>&1 &
   
   else
      wordpress_ip=$(ifconfig ens160 | grep 'netmask' | cut -d: -f2 | awk '{print $2}')
	  printf  "${NC}Current Status of Kubernetes is ${GREEN}INSTALLED\n"
	  printf "${NC}\n"
	  printf  "${NC}Starting Kasten K10, please wait\n"
          printf "${NC}\n"
	  sleep 15
	  killall -9 kubectl > /dev/null 2>&1 &
#	  sleep 15
	  wait_time=60
          seconds=0
          while (( seconds < wait_time )); do
            printf ". "
             sleep 10
            (( seconds += 10 ))
          done
	  microk8s kubectl -n kasten-io rollout restart deploy > /dev/null 2>&1 &
	  kasten_ip=$(ifconfig ens160 | grep 'netmask' | cut -d: -f2 | awk '{print $2}')
	  while [ "$(microk8s kubectl get pods -n kasten-io -o jsonpath='{.items[*].status.containerStatuses[0].ready}')" != "true true true true true true true true true true true true true true true true true true" ]; do
   	    printf ". "
            sleep 10
	  done
          clear
	  printf  "${NC}Kasten K10 is ready\n"
          printf "${NC}\n"
	  ./setup_minio.sh > /dev/null 2>&1 &
	  killall -9 kubectl > /dev/null 2>&1 & #stop any kubectl port-forward commands running in memory
	  sleep 5
	  
	  
	  current_ip=$(ifconfig ens160 | grep 'netmask' | cut -d: -f2 | awk '{print $2}')
	  microk8s kubectl --namespace kasten-io port-forward service/gateway 8080:8000 --address ${current_ip}  > /dev/null 2>&1 &

	  microk8s kubectl --namespace wordpress port-forward service/wordpress 8081:80 --address ${current_ip}  > /dev/null 2>&1 &

fi

}

readyMenu(){
	  
	  printf "${NC}Your Kasten K10 is reachable at ${GREEN}http://${current_ip}:8080/k10/#\n"
	  printf "${NC}Kasten K10 credentials are admin/Veeam123!\n"
	  printf "\n"
	  printf "${NC}Your Wordpress installation is reachable at ${GREEN}http://${current_ip}:8081/${NC}\n"
	  printf "\n"
	  printf "${NC}Option 1: Delete Wordpress. Do this after a successfull backup by K10:\n"
	  printf "${NC}Option 2: Re-run IP Address setup script. Do this if you are not getting an IP for K10.\n"
	  printf "${NC}Option 3: Reset Port-Forwarding. Do this if you are having K10 access issues.\n"
      read answer  # create variable to retains the answer
      case "$answer" in
        1) /root/delete_wordpress.sh ;;
		2) askIPAddress2 ;;
		3) resetPortForward ;;
        e) exit ;;
      esac
      echo -e "Hit the <return> key to continue..."
}

resetPortForward() {
   printf "${NC}Resetting Port-Forwarding...\n"
   current_ip=$(ifconfig ens160 | grep 'netmask' | cut -d: -f2 | awk '{print $2}')
   microk8s kubectl --namespace kasten-io port-forward service/gateway 8080:8000 --address ${current_ip}  > /dev/null 2>&1 &
   microk8s kubectl --namespace wordpress port-forward service/wordpress 8081:80 --address ${current_ip}  > /dev/null 2>&1 &
}

startNewInstall() {

wget -q --spider http://google.com
   if [ $? -eq 0 ]; then
    echo "You are Online. Starting Install"
   else
    echo "Cannot Reach Internet, Please re-run IP Address setup"
	read -p "Press [Enter] key to re-start IP setup..."
	askIPAddress
   fi



echo "Deploying K8s. Please Wait"
echo ""
/root/deployMicroK8S.sh &>/dev/null & disown


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

#END FUNCTIONS ##########################################################################





#Main Program Starts Here###################################################

clear

printBanner
   
printf  "${NC}Appliance Boot Detected - Please Configure IP Address Settings\n"
printCurrentIP
askIPAddress
checkMicroK8s
#readyMenu

while true
do
clear
printBanner
readyMenu   
done
#End Main Program###################################################################

#!/bin/bash
###############################
#Name: deployMicroK8s.sh
#Author: Adam Bergh
#Date: 07/07/2021 v1
#Kasten by Veeam
#Version: .1 Alpha
################################

IP_RANGE=$1

deployMicroK8S() {
#printf "${GREEN}Deploying MicroK8s\n"
snap install microk8s --classic
sleep 1m
microk8s enable dns registry istio helm3
sleep 2m
microk8s enable metallb:${IP_RANGE}
sleep 30
}

deployMicroK8S


#!/bin/bash
###############################
#Name: deployWordpress.sh
#Author: Adam Bergh
#Date: 07/07/2021 v1
#Kasten by Veeam
#Version: .1 Alpha
################################



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

deployWordpress
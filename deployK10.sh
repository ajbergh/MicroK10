#!/bin/bash
###############################
#Name: deployK10.sh
#Author: Adam Bergh
#Date: 07/07/2021 v1
#Kasten by Veeam
#Version: .1 Alpha
################################

deployK10 () {
	microk8s helm3 repo add kasten https://charts.kasten.io/
	microk8s kubectl create namespace kasten-io
	microk8s helm3 install k10 kasten/k10 --namespace=kasten-io \
	--set externalGateway.create=true \
	--set injectKanisterSidecar.enabled=true \
	--set auth.basicAuth.enabled=true \
	--set auth.basicAuth.htpasswd='admin:{SHA}w897J5HmKpAlulJ694w+DvVjSp8='
	
	sleep 4m
}

deployK10
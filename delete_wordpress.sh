#!/bin/bash
###############################
#Name: delete_wordpress.sh
#Author: Adam Bergh
#Date: 07/07/2021 v1
#Kasten by Veeam
#Version: .1 Alpha
################################

microk8s helm3 delete wordpress --namespace wordpress
#!/bin/bash
###############################
#Name: setup_minio.sh
#Author: Adam Bergh
#Date: 07/07/2021 v1
#Kasten by Veeam
#Version: .1 Alpha
################################

export MINIO_ACCESS_KEY="4DL07X9F9K6BFP4GCY5G"
export MINIO_SECRET_KEY="0NNX+buTu4Yrb40T2BbMww6lTT7hUk09nJApCO+S"
export MINIO_REGION_NAME="us-west-1"
#export MINIO_ROOT_USER=admin
#export MINIO_ROOT_PASSWORD=Veeam123
./minio server /miniodata --console-address ":9001" --config-dir /root > /dev/null 2>&1 &
#sleep 10
#local_ip=$(ifconfig ens160 | grep 'netmask' | cut -d: -f2 | awk '{print $2}')
#./mc config host add k10minio http://${local_ip}:9000 4DL07X9F9K6BFP4GCY5G 0NNX+buTu4Yrb40T2BbMww6lTT7hUk09nJApCO+S
#./mc mb k10minio/k10bucket

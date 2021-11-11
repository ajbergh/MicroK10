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
	--set injectKanisterSidecar.enabled=true \
	--set auth.basicAuth.enabled=true \
	--set auth.basicAuth.htpasswd='admin:{SHA}w897J5HmKpAlulJ694w+DvVjSp8='
	
	sleep 4m
}


setup_minio() {
	#wget https://dl.min.io/server/minio/release/linux-amd64/minio
	#chmod +x minio
	#wget https://dl.min.io/client/mc/release/linux-amd64/mc
	#chmod +x mc
	export MINIO_ACCESS_KEY="4DL07X9F9K6BFP4GCY5G"
	export MINIO_SECRET_KEY="0NNX+buTu4Yrb40T2BbMww6lTT7hUk09nJApCO+S"
	export MINIO_REGION_NAME="us-west-1"
	./minio server /miniodata --console-address ":9001" --config-dir /root > /dev/null 2>&1 &
}


create_location_profile () {
	microk8s kubectl create secret generic k10-s3-secret \
		  --namespace kasten-io \
		  --type secrets.kanister.io/aws \
		  --from-literal=aws_access_key_id=4DL07X9F9K6BFP4GCY5G \
		  --from-literal=aws_secret_access_key=0NNX+buTu4Yrb40T2BbMww6lTT7hUk09nJApCO+S

cat <<EOF >>minio-profile.yaml
apiVersion: config.kio.kasten.io/v1alpha1
kind: Profile
metadata:
  name: local-s3
  namespace: kasten-io
spec:
  locationSpec:
    type: ObjectStore
    objectStore:
      endpoint: http://10.0.1.1:9000
      name: k10bucket
      objectStoreType: S3
      region: us-west-1
      skipSSLVerify: true
    credential:
      secretType: AwsAccessKey
      secret:
        apiVersion: v1
        kind: secret
        name: k10-s3-secret
        namespace: kasten-io
  type: Location
EOF

microk8s kubectl apply -f minio-profile.yaml

}



deployK10
setup_minio
create_location_profile

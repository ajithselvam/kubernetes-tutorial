#!/bin/bash

path="/root/sso/sso.yaml"


kubectl create -f "$path"

sleep 10

kubectl get pods 

sleep 10

kubectl set image deploy sso sso=ajith567890/devops-portfolio-ajith:version4

kubectl rollout status deploy
sleep 10
kubectl get pods

sleep 10
kubectl delete service sso

sleep 5

kubectl expose deploy sso --type=NodePort --port=80

sleep 10
kubectl delete service sso

sleep 5
kubectl rollout undo deploy sso

sleep 5
kubectl scale deploy sso --replicas=0

sleep 5
kubectl get pods 

kubectl get service
sleep 5

echo "all done at $(date) by $(whoami) at location is $(path)"

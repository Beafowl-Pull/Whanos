#!/bin/bash

minikube start
eval $(minikube docker-env)
docker build -t whanos-jenkins .
helm install whanos helm/Whanos -f whanos.yaml
echo "$(minikube ip):$(kubectl get svc jenkins-nodeport -o jsonpath='{.spec.ports[0].nodePort}')"
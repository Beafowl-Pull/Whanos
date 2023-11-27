#!/bin/bash

# This script is used to deploy the application on the server
PORT=2
USER=root
SERVER=support.softwan.fr
PASSWORD=T@mybba0907

# Check if the server is reachable
function checkServer() {
    echo "Checking if the server is reachable..."
    ping -c 1 $SERVER > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Server is not reachable"
        exit 1
    fi
    echo "Server is reachable"
}

# Copy all the files to the server
function copyFiles() {
    echo "Copying files to the server..."
    sshpass -p $PASSWORD scp -P $PORT -r ./ $USER@$SERVER:/home/$USER/ > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Failed to copy files to the server"
        exit 1
    fi
    echo "Files copied to the server"
}

# Check if the server have helm, minikube and kubectl installed
function checkDependencies() {
    echo "Checking if the server have helm, minikube and kubectl installed..."
    sshpass -p $PASSWORD ssh -p $PORT $USER@$SERVER "helm version" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Helm is not installed on the server"
        exit 1
    fi
    sshpass -p $PASSWORD ssh -p $PORT $USER@$SERVER "minikube version" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Minikube is not installed on the server"
        exit 1
    fi
    sshpass -p $PASSWORD ssh -p $PORT $USER@$SERVER "kubectl version" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Kubectl is not installed on the server"
        exit 1
    fi
    echo "Helm, minikube and kubectl are installed on the server"
}

function checkIfRebootSystemctl() {
  echo "Checking if the server have reboot systemctl..."
  sshpass -p $PASSWORD ssh -p $PORT $USER@$SERVER "ls /usr/bin/reboot" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
      sshpass -p $PASSWORD scp -P $PORT -r ./utils/reboot $USER@$SERVER:/usr/bin/ > /dev/null 2>&1
      sshpass -p $PASSWORD scp -P $PORT -r ./utils/reboot.service $USER@$SERVER:/etc/systemd/system/ > /dev/null 2>&1
      sshpass -p $PASSWORD ssh -p $PORT $USER@$SERVER "chmod +x /usr/bin/reboot" > /dev/null 2>&1
      sshpass -p $PASSWORD ssh -p $PORT $USER@$SERVER "systemctl enable reboot.service" > /dev/null 2>&1
  fi
  echo "Reboot systemctl is installed on the server"
}

# Connect to the server and deploy the application
function deploy() {
    echo "Deploying the application..."
    sshpass -p $PASSWORD ssh -p $PORT $USER@$SERVER "reboot" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Failed to deploy the application"
        exit 1
    fi
    echo "Application deployed"
}

checkServer
checkDependencies
checkIfRebootSystemctl
copyFiles
deploy

#!/bin/bash

# Set namespace variable
NAMESPACE="maniaque"

# Function to check if the namespace exists
check_namespace() {
  kubectl get namespace $NAMESPACE &>/dev/null
  if [ $? -ne 0 ]; then
    echo "Namespace $NAMESPACE does not exist. Creating it now..."
    kubectl create namespace $NAMESPACE
  else
    echo "Namespace $NAMESPACE already exists."
  fi
}

# Function to apply MongoDB and Mongo-Express manifests
deploy_mongo_and_mongo_express() {
  echo "Deploying MongoDB..."
  kubectl apply -f mongo-deployment.yaml -n $NAMESPACE
  kubectl apply -f mongo-service.yaml -n $NAMESPACE

  echo "Waiting for MongoDB to be ready..."
  kubectl wait --for=condition=available --timeout=120s deployment/mongo -n $NAMESPACE

  echo "Deploying Mongo-Express..."
  kubectl apply -f mongo-express-deployment.yaml -n $NAMESPACE
  kubectl apply -f mongo-express-service.yaml -n $NAMESPACE

  echo "Waiting for Mongo-Express to be ready..."
  kubectl wait --for=condition=available --timeout=120s deployment/mongo-express -n $NAMESPACE
}

# Function to check NodePort and display Node IPs for access
get_node_access_info() {
  NODE_PORT=$(kubectl get svc mongo-express-service -n $NAMESPACE -o=jsonpath='{.spec.ports[0].nodePort}')
  NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

  echo "Mongo-Express is accessible at http://$NODE_IP:$NODE_PORT"
}

# Check for namespace and create if necessary
check_namespace

# Deploy MongoDB and Mongo-Express
deploy_mongo_and_mongo_express

# Display NodePort and Node IP for accessing Mongo-Express
get_node_access_info
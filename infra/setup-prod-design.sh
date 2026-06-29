#!/bin/bash
# setup-prod-design.sh
# MLOps Design Script: Provisions isolated dev and prod workspaces alongside a shared model registry.

# ---------------------------------------------------------------------------
# Shared variables & Randomized Suffix Generation
# ---------------------------------------------------------------------------
guid=$(cat /proc/sys/kernel/random/uuid)
suffix=${guid//[-]/}
suffix=${suffix:0:18}

RESOURCE_PROVIDER="Microsoft.MachineLearningServices"
REGIONS=("eastus" "westus" "centralus" "northeurope" "westeurope")
RANDOM_REGION=${REGIONS[$RANDOM % ${#REGIONS[@]}]}

# Dev environment
DEV_RESOURCE_GROUP="rg-ai300-dev-${suffix}"
DEV_WORKSPACE_NAME="mlw-ai300-dev-${suffix}"

# Prod environment
PROD_RESOURCE_GROUP="rg-ai300-prod-${suffix}"
PROD_WORKSPACE_NAME="mlw-ai300-prod-${suffix}"

# Shared registry (one per subscription/region)
REGISTRY_RESOURCE_GROUP="rg-ai300-reg-${suffix}"
REGISTRY_NAME="mlr-ai300-shared-${suffix}"

# Compute resources (dev only for interactive experimentation)
COMPUTE_INSTANCE="ci${suffix}"
COMPUTE_CLUSTER="aml-cluster"

echo "==================================================================="
echo "Starting MLOps Environment Setup Design"
echo "Region selected: $RANDOM_REGION"
echo "==================================================================="

# ---------------------------------------------------------------------------
# Register the Azure Machine Learning resource provider
# ---------------------------------------------------------------------------
echo "Registering the Machine Learning resource provider..."
az provider register --namespace $RESOURCE_PROVIDER

# ---------------------------------------------------------------------------
# Phase 1: Provision Dev Environment & Experimentation Data
# ---------------------------------------------------------------------------
echo "--> Creating Dev Resource Group: $DEV_RESOURCE_GROUP"
az group create --name $DEV_RESOURCE_GROUP --location $RANDOM_REGION

echo "--> Creating Dev Workspace: $DEV_WORKSPACE_NAME"
az ml workspace create --name $DEV_WORKSPACE_NAME --resource-group $DEV_RESOURCE_GROUP --location $RANDOM_REGION

az configure --defaults group=$DEV_RESOURCE_GROUP workspace=$DEV_WORKSPACE_NAME

echo "--> Creating Dev Compute Instance: $COMPUTE_INSTANCE"
az ml compute create --name $COMPUTE_INSTANCE --size STANDARD_DS11_V2 --type ComputeInstance

echo "--> Creating Dev Compute Cluster: $COMPUTE_CLUSTER"
az ml compute create --name $COMPUTE_CLUSTER --size STANDARD_DS11_V2 --max-instances 2 --type AmlCompute

echo "--> Registering Dev Data Assets..."
az ml data create --type mltable --name "diabetes-training" --path ../data/diabetes-data
az ml data create --type uri_file --name "diabetes-data" --path ../data/diabetes-data/diabetes.csv
az ml data create --type uri_folder --name "diabetes-dev-folder" --path ../data/diabetes-data

# ---------------------------------------------------------------------------
# Phase 2: Provision Prod Environment & Production Data
# ---------------------------------------------------------------------------
echo "--> Creating Prod Resource Group: $PROD_RESOURCE_GROUP"
az group create --name $PROD_RESOURCE_GROUP --location $RANDOM_REGION

echo "--> Creating Prod Workspace: $PROD_WORKSPACE_NAME"
az ml workspace create --name $PROD_WORKSPACE_NAME --resource-group $PROD_RESOURCE_GROUP --location $RANDOM_REGION

az configure --defaults group=$PROD_RESOURCE_GROUP workspace=$PROD_WORKSPACE_NAME

echo "--> Registering Prod Data Asset (Isolated from Dev)..."
az ml data create --type uri_folder --name "diabetes-prod-folder" --path ../production/data

# ---------------------------------------------------------------------------
# Phase 3: Provision Shared Model Registry
# ---------------------------------------------------------------------------
echo "--> Creating Registry Resource Group: $REGISTRY_RESOURCE_GROUP"
az group create --name $REGISTRY_RESOURCE_GROUP --location $RANDOM_REGION

echo "--> Rendering registry.yml with dynamic placeholders..."
sed \
    -e "s|REGISTRY_NAME_PLACEHOLDER|$REGISTRY_NAME|g" \
    -e "s|PRIMARY_REGION_PLACEHOLDER|$RANDOM_REGION|g" \
    registry.yml > registry.generated.yml

echo "--> Creating Shared Azure Machine Learning Registry: $REGISTRY_NAME"
az ml registry create --file registry.generated.yml --resource-group $REGISTRY_RESOURCE_GROUP

echo "==================================================================="
echo "Provisioning Complete!"
echo "  Dev Workspace:   $DEV_WORKSPACE_NAME ($DEV_RESOURCE_GROUP)"
echo "  Prod Workspace:  $PROD_WORKSPACE_NAME ($PROD_RESOURCE_GROUP)"
echo "  Shared Registry: $REGISTRY_NAME ($REGISTRY_RESOURCE_GROUP)"
echo "==================================================================="

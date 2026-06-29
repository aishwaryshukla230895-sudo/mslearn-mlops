#!/bin/bash
# setup-multi-env.sh
# Multi-environment automation entry point for MLOps pipelines.
# Usage: ./setup-multi-env.sh [dev|prod]

ENVIRONMENT=${1:-dev}

echo "==================================================================="
echo "Initializing MLOps Environment Provisioning for target: [ $ENVIRONMENT ]"
echo "==================================================================="

# Generate randomized suffix or read from existing configuration
guid=$(cat /proc/sys/kernel/random/uuid)
suffix=${guid//[-]/}
suffix=${suffix:0:18}

RESOURCE_PROVIDER="Microsoft.MachineLearningServices"
REGIONS=("eastus" "westus" "centralus" "northeurope" "westeurope")
RANDOM_REGION=${REGIONS[$RANDOM % ${#REGIONS[@]}]}

# Define environment-specific variables
if [ "$ENVIRONMENT" = "prod" ]; then
    RESOURCE_GROUP="rg-ai300-prod-${suffix}"
    WORKSPACE_NAME="mlw-ai300-prod-${suffix}"
    DATA_NAME="diabetes-prod-folder"
    DATA_PATH="../production/data"
else
    RESOURCE_GROUP="rg-ai300-dev-${suffix}"
    WORKSPACE_NAME="mlw-ai300-dev-${suffix}"
    DATA_NAME="diabetes-dev-folder"
    DATA_PATH="../data/diabetes-data"
fi

# Shared registry across all environments
REGISTRY_RESOURCE_GROUP="rg-ai300-reg-${suffix}"
REGISTRY_NAME="mlr-ai300-shared-${suffix}"

echo "Target Resource Group: $RESOURCE_GROUP"
echo "Target Workspace:      $WORKSPACE_NAME"
echo "Shared Registry:       $REGISTRY_NAME"
echo "-------------------------------------------------------------------"

# Register provider
az provider register --namespace $RESOURCE_PROVIDER

# 1. Ensure Shared Registry exists (shared asset across dev/prod)
echo "Ensuring shared registry resource group exists..."
az group create --name $REGISTRY_RESOURCE_GROUP --location $RANDOM_REGION

sed -e "s|REGISTRY_NAME_PLACEHOLDER|$REGISTRY_NAME|g" \
    -e "s|PRIMARY_REGION_PLACEHOLDER|$RANDOM_REGION|g" \
    registry.yml > registry.generated.yml

echo "Creating/Updating shared registry..."
az ml registry create --file registry.generated.yml --resource-group $REGISTRY_RESOURCE_GROUP

# 2. Provision Environment-Specific Workspace
echo "Creating $ENVIRONMENT resource group..."
az group create --name $RESOURCE_GROUP --location $RANDOM_REGION

echo "Creating $ENVIRONMENT workspace..."
az ml workspace create --name $WORKSPACE_NAME --resource-group $RESOURCE_GROUP --location $RANDOM_REGION
az configure --defaults group=$RESOURCE_GROUP workspace=$WORKSPACE_NAME

# 3. Provision Compute (Only for dev experimentation)
if [ "$ENVIRONMENT" = "dev" ]; then
    echo "Provisioning interactive compute instance for dev..."
    az ml compute create --name "ci${suffix}" --size STANDARD_DS11_V2 --type ComputeInstance
fi

echo "Provisioning training cluster..."
az ml compute create --name "aml-cluster" --size STANDARD_DS11_V2 --max-instances 2 --type AmlCompute

# 4. Register Isolated Environment Data
echo "Registering isolated data asset [$DATA_NAME]..."
az ml data create --type uri_folder --name $DATA_NAME --path $DATA_PATH

echo "==================================================================="
echo "Successfully provisioned target environment: $ENVIRONMENT"
echo "==================================================================="

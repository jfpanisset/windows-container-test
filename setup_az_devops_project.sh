#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
# Copyright Contributors to the ASWF Sample Project

# Assuming existing:
#
# - Local install of Azure CLI
# - Azure DevOps organization
# - Azure DevOps Personal Access Token
# - GitHub user/organization
# - GitHub Personal Access Token
# - GitHub Project
# - Docker Hub user
# - Docker Hub Personal Access Token
# - Docker Hub user email
#
# this script will create an Azure DevOps project that matches the GitHub project, create service connections to
# GitHub and Docker Hub, and a build pipeline that gets triggered on changes to the master branch of the
# GitHub project.
#
# Call with:
# ./setup_az_devops_project.sh AZ_DEVOPS_ORG AZ_DEVOPS_PAT GITHUB_USER GITHUB_PAT GITHUB_PROJECT DOCKER_HUB_USER DOCKER_HUB_PAT DOCKER_HUB_EMAIL
#

if [[ $# -ne 8 ]]; then
    echo "Usage: " $0 "AZ_DEVOPS_ORG AZ_DEVOPS_PAT GITHUB_USER GITHUB_PAT GITHUB_PROJECT DOCKER_HUB_USER DOCKER_HUB_PAT DOCKER_HUB_EMAIL"
    exit 1
fi

# Make sure the azure-devops extension to the "az" Azure CLI is installed

if ! az extension show --name azure-devops > /dev/null; then
    echo "adding Azure DevOps extension to Azure CLI"
    az extension add --name azure-devops
else
    echo "azure-devops extension is already installed"
fi

# AZURE_DEVLOPS_EXT_PAT and AZURE_DEVOPS_EXT_GITHUB_PAT are special environment variables recognized by the az CLI

export AZURE_DEVOPS_ORG_NAME=$1
export AZURE_DEVOPS_EXT_PAT=$2
export GITHUB_USER=$3
export AZURE_DEVOPS_EXT_GITHUB_PAT=$4
export GITHUB_PROJECT=$5
export DOCKER_HUB_USER=$6
export DOCKER_HUB_TOKEN=$8
export DOCKER_HUB_EMAIL=$8

# Create Azure DevOps project, set organization and project to be the default
az devops configure --defaults organization=https://dev.azure.com/$AZURE_DEVOPS_ORG_NAME
az devops project create --name $GITHUB_PROJECT --source-control git --visibility public
az devops configure --defaults project=$GITHUB_PROJECT

# Create the service connection to GitHub
az devops service-endpoint github create --github-url https://github.com/$GITHUB_USER/$GITHUB_PROJECT/settings --name $GITHUB_PROJECT.github.connection

# We need the object ID for the GitHub connection
export GITHUB_CONNECTION_ID=$(az devops service-endpoint list  --query "[?name=='"$GITHUB_PROJECT".github.connection'].id" -o tsv)

# Create the build pipeline
az pipelines create --name $GITHUB_PROJECT.ci --repository $GITHUB_USER/$GITHUB_PROJECT --branch master --repository-type github \
    --service-connection $GITHUB_CONNECTION_ID --skip-first-run --yml-path /azure-pipelines.yml

# To use the pre-defined Docker@2 Azure Pipelines task, we need a service connection to Docker Hub. 
sed -e 's/DOCKER_HUB_USER/'$DOCKER_HUB_USER'/' \
    -e 's/DOCKER_HUB_TOKEN/'$DOCKER_HUB_TOKEN'/' \
    -e 's/DOCKER_HUB_EMAIL/'$DOCKER_HUB_EMAIL'/' \
    -e 's/DOCKER_HUB_CONNECTION/'$GITHUB_PROJECT'.dockerhub.connection/' \
    docker_hub_endpoint.json | \
az devops service-endpoint create --service-endpoint-configuration /dev/stdin

# Workaround for current lack of API for setting the "Allow all pipelines to use this service connection" property.
export DOCKER_HUB_CONNECTION_ID=$(az devops service-endpoint list --query "[?name=='"$GITHUB_PROJECT".dockerhub.connection'].id" -o tsv)
sed -e 's/DOCKER_HUB_CONNECTION_ID/'$DOCKER_HUB_CONNECTION_ID'/' \
    -e 's/DOCKER_HUB_CONNECTION/name-of-docker-hub-service-endpoint/' \
    docker_hub_endpoint_auth.json | \
az devops invoke --http-method patch --area build --resource authorizedresources \
    --route-parameters project=$GITHUB_PROJECT --api-version 5.0-preview --in-file /dev/stdin --encoding ascii

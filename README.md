# windows-container-test

This project demonstrates building a Windows Docker container with Visual Studio, CMake and git, with the objective of being to implement the VFX Reference Platform compliant ASWF build containers from https://github.com/AcademySoftwareFoundation/aswf-docker

## Windows Version Requirements

Docker on Windows requires that containers are built from a base images of the same Windows version (or more specifically Build version) than the system on which they will run. As of Fall 2019 the only Microsoft hosted Azure Pipelines Windows build agent with Container support enabled is running Windows Server Core 2016 Build 1803:

https://github.com/Microsoft/azure-pipelines-image-generation/blob/master/images/win/WindowsContainer1803-Readme.md

These build agents already cache some base images, so to save disk space (both when generating the container and when ultimately using it on the same type of build agent) we will use the following base image:

```
mcr.microsoft.com/windows/servercore:1803
```

## Setting Up Azure Pipelines

For a more detailed discussion on setting up an Azure DevOps / Azure Pipelines CI environment see [Continuous Integration with Azure DevOps in the ASWF Sample Project](https://github.com/jfpanisset/aswf-sample-project#continuous-integration-with-azure-devops--azure-pipeline). We will use the Azure CLI to create a corresponding Azure DevOps project:

```
az extension add --name azure-devops
export AZURE_DEVOPS_EXT_PAT=YOUR_AZDEVOPS_PAT
az devops configure --defaults organization=https://dev.azure.com/AZDEVOPS_ORG_NAME
az devops project create --name AZDEVOPS_PROJECT_NAME --source-control git --visibility public
az devops configure --defaults project=AZDEVOPS_PROJECT_NAME
```

Create the service connection to the GitHub project:

```
export AZURE_DEVOPS_EXT_GITHUB_PAT=YOUR_GITHUB_PAT
az devops service-endpoint github create --github-url https://github.com/GITHUB_ACCOUNT/GITHUB_PROJECT/settings --name GITHUB_PROJECT.connection
```

To authenticate against Docker Hub to push the newly built image requires a [Docker Hub Personnal Access Token](https://www.docker.com/blog/docker-hub-new-personal-access-tokens/). Record this PAT in a secure location before dismissing the creation window.

Next save this token to a secret Azure Pipelines secret variable called `DOCKER_HUB_TOKEN`:

```
az pipelines variable create --name DOCKER_HUB_TOKEN --value YOUR_DOCKER_HUB_TOKEN --secret true --allow-override true --pipeline-name GITHUB_PROJECT.ci
```
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

For a more detailed see the discussion on [Continuous Integration with Azure DevOps in the ASWF Sample Project](https://github.com/jfpanisset/aswf-sample-project#continuous-integration-with-azure-devops--azure-pipeline).

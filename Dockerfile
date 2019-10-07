# escape=`

# On Windows the container has to be based on the same Windows version ("Build") as the host that runs it.
# Microsoft hosted Azure Pipelines build agents currently only support running containers on Windows Server
# Core 1803. Also Build Tools 2019 require the .net 4.8 framework: if not present the installer will try
# to install it, leaving the container in "needs a reboot" state. Thus we cannot use the generic
# mcr.microsoft.com/windows/servercore:1803 Server Core image (which is pre-cached on these build
# agents), we need one where .net 4.8 has already been installed. 
#ARG FROM_IMAGE=mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-1803
ARG FROM_IMAGE=mcr.microsoft.com/windows/servercore:1803
FROM ${FROM_IMAGE}

# We're using PowerShell as the default shell
SHELL ["powershell", "-Command"]

# Copy our Install script.
#COPY Install.cmd C:/TEMP/

# Download collect.exe in case of an install failure.
#ADD https://aka.ms/vscollect.exe C:/TEMP/collect.exe

# Use the latest release channel. For more control, specify the location of an internal layout.
ARG CHANNEL_URL=https://aka.ms/vs/16/release/channel
ADD ${CHANNEL_URL} C:/TEMP/VisualStudio.chman

# Download and install Build Tools excluding workloads and components with known issues.
ADD https://aka.ms/vs/16/release/vs_buildtools.exe C:\TEMP\vs_buildtools.exe
# Prefix with C:\TEMP\Install.cmd to enable log gathering
# Note that --wait option to installer doesn't actually wait, so you want to tell powershell
# to explicitly wait for install to complete
#RUN Start-Process C:\TEMP\vs_buildtools.exe -Wait -ArgumentList `
#    --quiet, `
#    --wait, `
#    --norestart, `
#    --nocache, `
#    --installPath,C:\BuildTools, `
#    --channelUri,C:\TEMP\VisualStudio.chman, `
#    --installChannelUri,C:\TEMP\VisualStudio.chman, `
#    --add,Microsoft.VisualStudio.Workload.MSBuildTools, `
#    --add,Microsoft.VisualStudio.Workload.VCTools, `
#    --includeRecommended

# Install CMake
ADD https://github.com/Kitware/CMake/releases/download/v3.15.4/cmake-3.15.4-win64-x64.msi C:\TEMP\cmake.msi
RUN Start-Process msiexec.exe -Wait -ArgumentList '/I C:\TEMP\cmake.msi /quiet' ;  `
    [Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\Program Files\CMake\bin', 'Machine') ; `
    Remove-Item -Path 'C:\TEMP\cmake.msi'

# Install git
ADD https://github.com/git-for-windows/git/releases/download/v2.23.0.windows.1/Git-2.23.0-64-bit.exe C:\TEMP\git.exe
RUN Start-Process C:\TEMP\git.exe -Wait -ArgumentList `
    '/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh"' ;`
    Remove-Item -Path 'C:\TEMP\git.exe'

# Start developer command prompt with any other commands specified. Unfortunately no PowerShell version of vsdevcmd.bat
# so we extract the environment variables it created / changed and stick those into PowerShell env:
# This is useful for a standalone development container, for Azure Pipelines will use "docker create" to start
# a long running container with a "keep alive" Node.JS process and then "docker exec" to execute commands
# inside the container, so there shouldn't be a ENTRYPOINT specified for these build container images.
# Also CMake is able to find the Visual Studio compiler without having to run VsDevCmd.bat

#ENTRYPOINT & \"${env:COMSPEC}\" /s /c \"C:\BuildTools\Common7\Tools\VsDevCmd.bat -no_logo && set\" | `
#           foreach-object { $name, $value = $_ -split '=', 2 ; set-content env:\"$name\" $value } ;

# Default to PowerShell if no other command specified.
#CMD powershell.exe -NoLogo -ExecutionPolicy Bypass


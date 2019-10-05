# escape=`

# Use a specific tagged image. Tags can be changed, though that is unlikely for most images.
# You could also use the immutable tag @sha256:324e9ab7262331ebb16a4100d0fb1cfb804395a766e3bb1806c62989d1fc1326
ARG FROM_IMAGE=mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019
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
RUN Start-Process C:\TEMP\vs_buildtools.exe -Wait -ArgumentList `
    --quiet, `
    --wait, `
    --norestart, `
    --nocache, `
    --installPath,C:\BuildTools, `
    --channelUri,C:\TEMP\VisualStudio.chman, `
    --installChannelUri,C:\TEMP\VisualStudio.chman, `
    --add,Microsoft.VisualStudio.Workload.MSBuildTools, `
    --add,Microsoft.VisualStudio.Workload.VCTools, `
    --includeRecommended

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
ENTRYPOINT & \"${env:COMSPEC}\" /s /c \"C:\BuildTools\Common7\Tools\VsDevCmd.bat -no_logo && set\" | `
           foreach-object { $name, $value = $_ -split '=', 2 ; set-content env:\"$name\" $value } ;

# Default to PowerShell if no other command specified.
CMD powershell.exe -NoLogo -ExecutionPolicy Bypass


Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force 
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module xActiveDirectory, xNetworking, xStorage -Force 
Install-Module xPSDesiredStateConfiguration -Force
Install-Module DSCR_Application -Force
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 
choco install -y git -force
new-item 'C:\bitbucket' -ItemType directory
Invoke-WebRequest -Uri https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-5.16.0-x64.exe -outfile 'C:\bitbucket\setup.exe'
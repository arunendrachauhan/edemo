Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force 
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module xActiveDirectory, xNetworking, xStorage -Force 
Install-Module xPSDesiredStateConfiguration -Force
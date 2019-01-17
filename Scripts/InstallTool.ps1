configuration InstallTool             
{             
   param             
    (             
    
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds
    )

    Import-DscResource -ModuleName DSCR_Application            
    
	[System.Management.Automation.PSCredential ]$VMCreds = New-Object System.Management.Automation.PSCredential ( "$AdminCreds.UserName", $AdminCreds.Password)
	#$domainCreds = (Get-Credential -UserName "$(($DomainName -split '\.')[0])\$($AdminCreds.UserName)", $AdminCreds.Password)
	

   
    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)
	
    Node localhost             
    {             
            
        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true            
        }            
            
        cApplication AtlassianBitbucket
        {
        Name = '*Bitbucket*'   # You can use RegExp when Fuzzy=$true
        Fuzzy = $true
        Version = '5.16.0'
        Ensure = 'Present'
        InstallerPath = "C:\bitbucket\setup.exe"
        Arguments = '-install ALLUSERS=1 /S /quite'
        NoRestart = $true
        }
            
    }             
}        
            


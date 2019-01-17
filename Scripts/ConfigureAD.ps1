configuration ConfigureAD             
{             
   param             
    (             
        [Parameter(Mandatory)]
        [String]$DomainName,
        
        [Parameter(Mandatory)]
        [String]$DnsForwarder,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds
    )             
            
    Import-DscResource -ModuleName xActiveDirectory, xStorage, xNetworking            
    
	[System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ( "$(($DomainName -split '\.')[0])\$($AdminCreds.UserName)", $AdminCreds.Password)
	#$domainCreds = (Get-Credential -UserName "$(($DomainName -split '\.')[0])\$($AdminCreds.UserName)", $AdminCreds.Password)
	

    $safeModeAdminCreds = New-Object System.Management.Automation.PSCredential ( "(Password Only)", $AdminCreds.Password)

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
            
        File ADFiles            
        {            
            DestinationPath = 'D:\NTDS'            
            Type = 'Directory'            
            Ensure = 'Present'            
        }            
        
		WindowsFeature DNS
        {
            Ensure = "Present"
            Name = "DNS"
        }
        
        WindowsFeature DnsTools
        {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
        }
        
        Script SetDNSForwarder
        {
            #
            # 
            #
            SetScript =
            {
                $dnsrunning = $false
                $triesleft = $Using:RetryCount
                While (-not $dnsrunning -and ($triesleft -gt 0))
                {
                    $triesleft--
                    try
                    {
                        $dnsrunning = (Get-Service -name dns).Status -eq "running"
                    } catch {
                        $dnsrunning = $false
                    }
                    if (-not $dnsrunning)
                    {
                        Write-Verbose -Verbose "Waiting $($Using:RetryIntervalSec) seconds for DNS service to start"
                        Start-Sleep -Seconds $Using:RetryIntervalSec
                    }
                }

                if (-not $dnsrunning)
                {
                    Write-Warning "DNS service is not running, cannot edit forwarder. Template deployment will fail."
                    # but continue anyway.
                }
                try {
                    Write-Verbose -Verbose "Getting list of DNS forwarders"
                    $forwarderlist = Get-DnsServerForwarder
                    if ($forwarderlist.IPAddress)
                    { 
                        Write-Verbose -Verbose "Removing forwarders"
                        Remove-DnsServerForwarder -IPAddress $forwarderlist.IPAddress -Force
                    } else {
                        Write-Verbose -Verbose "No forwarders found"
                    }
                } catch {
                    Write-Warning -Verbose "Exception running Remove-DNSServerForwarder: $_"
                }
                try {
                    Write-Verbose -Verbose "setting  forwarder to $($using:DNSForwarder)"
                    Set-DnsServerForwarder -IPAddress $using:DNSForwarder
                } catch {
                    Write-Warning -Verbose "Exception running Set-DNSServerForwarder: $_"
                }
                 
            }
            GetScript =  { @{} }
            TestScript = { $false }
            DependsOn = "[WindowsFeature]DNSTools"
        }
		                
		WindowsFeature GPOTools
        {
            Ensure = "Present"
            Name = "GPMC"
            DependsOn = "[WindowsFeature]DNS"
        }

        WindowsFeature ADDFSTools
        {
            Ensure = "Present"
            Name = "RSAT-DFS-Mgmt-Con"
            DependsOn = "[WindowsFeature]DNS"
        }

        xWaitforDisk Disk2
        {
            DiskID = 2
            RetryIntervalSec =$RetryIntervalSec
            RetryCount = $RetryCount
        }
        
        xDisk ADDataDisk
        {
            DiskID = 2
            DriveLetter = "F"
            DependsOn = "[xWaitForDisk]Disk2"
        }
        
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            DependsOn = "[xDisk]ADDataDisk"
        }
				          
            
        # Optional GUI tools            
        WindowsFeature ADDSTools            
        {             
            Ensure = "Present"             
            Name = "RSAT-ADDS"             
        }            

        #
        # make sure the machine looks to itself for DNS now.
        #
        xDnsServerAddress DnsServerAddress
        {
            Address        = '127.0.0.1'
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn = "[WindowsFeature]DNS"
        }
		
        # No slash at end of folder paths            
        xADDomain FirstDS             
        {             
            DomainName = $DomainName             
            DomainAdministratorCredential = $domainCreds
            SafeModeAdministratorPassword = $safeModeAdminCreds             
            DatabasePath = 'D:\NTDS'            
            LogPath = 'D:\NTDS'
			SysvolPath = "F:\SYSVOL"
            DependsOn = "[WindowsFeature]ADDSInstall","[File]ADFiles","[xDnsServerAddress]DnsServerAddress", "[Script]SetDNSForwarder", "[xDisk]ADDataDisk"            
        }            
            
    }             
}        
            


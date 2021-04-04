# Installation des services Active Directory
Install-windowsfeature -name AD-Domain-Services -IncludeAllSubFeature –IncludeManagementTools

# installation du serveur DNS
Install-WindowsFeature -Name DNS -IncludeAllSubFeature –IncludeManagementTools

# création du domaine
Install-ADDSForest `
	-CreateDnsDelegation:$false `
	-DatabasePath "C:\Windows\NTDS" `
	-DomainMode "WinThreshold" `
	-DomainName "domain.local" `
	-DomainNetbiosName "domain" `
	-ForestMode "WinThreshold" `
	-InstallDns:$true `
	-LogPath "C:\Windows\NTDS" `
	-NoRebootOnCompletion:$false `
	-SysvolPath "C:\Windows\SYSVOL" `
	-Force:$true
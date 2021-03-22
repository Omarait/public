# =======================================================
# NAME: starwind-manager.ps1
# AUTHOR: AIT-MOULID Omar
# DATE: 28/05/2018
#
# KEYWORDS: Starwind, SAN, ISCSI
#
# =======================================================

# =======================================================
# Import du module Starwind et variables globales
# =======================================================

Clear-host

Import-Module StarWindX

$close = $null
$server = $null
$srv = ""
$port = ""

# =======================================================
# Fonction principale : startprogram
# Utilisation : se lance au démarrage du script, fait office de menu principal
# =======================================================

Function startprogram
{
    do 
    {
		# Affichage informatif sur le serveur en cours d'utilisation
	    if ($global:server) { Write-host "Connected to Server $global:srv on port $global:port" -foreground green }
	    Write-host ""
		# Menu
	    Write-host "##################################" -foreground yellow
	    Write-host "[0] Connect to Server"
	    Write-host "[1] Disconnect"
	    Write-host "[2] Enumerate all Targets and Devices"
	    Write-host "[3] Create Device"
	    Write-host "[4] Extend Device"
	    Write-host "[5] Remove Device"
	    Write-host "[6] Remove Target"
	    Write-host "[7] Disconnect and close"
	    Write-host "##################################" -foreground yellow
	    Write-host ""
	    $choice = Read-host "Enter your choice" 

		# Appel des fonctions selon le choix
	    switch ($choice)
	    {
		    0 { connect_starwind }
		    1 { disconnect_starwind }
		    2 { enumdevices }
		    3 { createdevice }
		    4 { extenddevice }
		    5 { removedevice }
		    6 { removetarget }
		    7 { if ($global:server) { disconnect_starwind }; $close = 1 }
	    }
	    Clear-host
    }
    while ($close -eq $null)
}

# =======================================================
# Fonction connect_starwind
# Utilisation : Demande à l'utilisateur les informations pour la connexion au serveur
# =======================================================

Function connect_starwind
{

	try
	{
		Write-host ""
		# Entrée des informations de connexions
		if (($global:srv = Read-host -Prompt "Server name or ip [default : localhost]") -eq "") {$global:srv = "localhost"}
		if (($global:port = Read-host -Prompt "Port [default : 3261]") -eq "") {$global:port = "3261"}
		if (($user = Read-host -Prompt "Username [default : root]") -eq "") {$user = "root"}
		if (($password = Read-host -Prompt "Password [default : starwind]") -eq "") {$password = "starwind"}

		# Initialisation de la connexion au serveur
		$global:server = New-SWServer $global:srv $global:port $user $password
		$global:server.Connect()
	}
	catch
	{
		# En cas d'erreur, afficher le message et attendre la validation
		Write-host $_ -foreground red
		Read-host "Press enter to return to menu"
	}
}

# =======================================================
# Fonction disconnect_starwind
# Utilisation : Déconnexion du serveur
# =======================================================

Function disconnect_starwind
{	
	# Déconnexion du serveur
	$global:server.Disconnect()
	$global:server = $null
}

# =======================================================
# Fonction enumdevices
# Utilisation : Affiche la liste des targets et des devices
# =======================================================

Function enumdevices
{
	Clear-host
	# Pour chaque target trouvé sur le serveur
	foreach($target in $global:server.Targets)
	{
		# Afficher le nom et l'alias
		Write-host "#################################" -foreground yellow
		Write-host ""
		Write-host "Target" -foreground yellow
		Write-host "------"
		Write-host ""
		$targetname = $target.name
		$targetalias = $target.alias
		Write-host "Name : $targetname"
		Write-host "Alias : $targetalias"
		Write-host ""
		# Afficher le nom, le chemin de fichier et la taille des devices attachés au target
		Write-host "Devices" -foreground yellow
		Write-host "-------"
		$i=0
		foreach ($device in $target.devices)
		{
			$devicename = $device.name
			$devicesize = $device.size
			$devicefile = $device.file
			Write-host "Device n° $i"
			Write-host "Name : $devicename"
			Write-host "File : $devicefile"
			Write-host "Size : $devicesize"
			Write-host "" 
			$i++
		}
		Write-host ""
		Write-host "#################################" -foreground yellow
		Write-host ""
	}
	
	# Affichage des devices attachés à aucun target
	Write-host "Devices not attached to target" -foreground yellow
	Write-host "-------"
	Write-host ""
   	foreach($device in $global:server.devices)
	{
		if ($device.targetid -like "empty")
		{
			$device
		}
	}

	Read-host "Press enter to return to menu"
}

# =======================================================
# Fonction createdevice
# Utilisation : Demande à l'utilisateur les informations pour la création d'un nouveau device et d'un nouveau target
# =======================================================

Function createdevice
{
    Clear-host
    Write-host "Create image file and a new target"
	Write-host ""

	# Entrée des informations du device à créer
	$filename = Read-Host "File Name"
	$path = Read-Host "Path (exemple C:\Starwind\Storage)"
	[int]$size = Read-Host "Size in Mo"
	$targetalias = Read-Host "Target Alias"

	# Création du fichier
	New-ImageFile -server $global:server -path $path -fileName $filename -size $size
    
	# Création du device
	$device = Add-ImageDevice -server $global:server -path $path -fileName $filename -sectorSize 512 -NumaNode 0
    
	# Création du target
	New-Target -server $global:server -alias $targetalias -devices $device.Name

	# Affichage du résultat
	Write-host "#################################" -foreground yellow
	Write-host "Result" -foreground yellow
	$global:server.disconnect()
	$global:server.connect()
	$global:server.Targets | Where-Object alias -eq $targetalias
	$global:server.Devices | Where-Object file -like "*$filename.img"
	Write-host "#################################" -foreground yellow
	
	Read-host "Press enter to return to menu"
}

Function removedevice
{
	Clear-Host
	Write-Host "#################################" -foreground yellow
	foreach($device in $global:server.Devices)
	{
		$devicename = $device.name
		$devicefile = $device.file
		Write-host "Name : $devicename"
		Write-host "File : $devicefile"
		Write-host "-------------------" 
	}

	write-host "#################################" -foreground yellow
	$name = Read-Host "Enter the device's name to remove"
	try {
		$devicefile = (Get-Device -server $global:server -deviceId $global:server.GetDeviceID($name)).file
		Remove-Device -server $global:server -deviceId $global:server.GetDeviceID($name) -force $true
		Remove-Item $devicefile
	} catch {}
	write-host "#################################" -foreground yellow
	write-host "Device removed" -foreground yellow
	
	$global:server.disconnect()
	$global:server.connect()
	Read-Host "Press enter to return to menu"
}

Function removetarget
{
	Clear-Host
	Write-Host "#################################" -foreground yellow
	foreach($target in $global:server.Targets)
	{
		$targetname = $target.name
		$targetalias = $target.alias
		Write-host "Name : $targetname"
		Write-host "Alias : $targetalias"
		Write-host "-------------------" 
	}

	write-host "#################################" -foreground yellow
	write-host ""
	$name = Read-Host "Enter the target's name to remove"
	
	Remove-Target -server $global:server -name $name -force $true
	
	write-host "#################################" -foreground yellow
	write-host "Target removed" -foreground yellow

	$global:server.disconnect()
	$global:server.connect()
	Read-Host "Press enter to return to menu"
}

Function extenddevice
{
	Clear-Host
	Write-Host "#################################" -foreground yellow
	foreach($device in $global:server.Devices)
	{
		$devicename = $device.name
		$devicefile = $device.file
		$devicesize = $device.size
		Write-host "Name : $devicename"
		Write-host "File : $devicefile"
		Write-host "Size : $devicesize"
		Write-host "-------------------" 
	}

	write-host "#################################" -foreground yellow
	$devicename = Read-Host "Device Name"
	$size = Read-Host "Size in MB"

	$device = Get-Device $global:server -name $deviceName
	if( !$device )
	{
		Write-Host "Device not found" -foreground red
	}
	else 
	{
		try {
			$device.ExtendDevice($size) # Specify the amount of disk space you want to add to the virtual disk volume.
			write-host "#################################" -foreground yellow
			write-host "Image extended, check size :" -foreground yellow
			$device = Get-Device $global:server -name $deviceName
			$device
		} catch {write-host $_}
		Read-Host "Press enter to return to menu"
	}
}

# =======================================================
# Démarrage de la fonction principale, affichage du menu
# =======================================================

startprogram

# =======================================================
# Suppression des variables
# =======================================================

Remove-Variable close
Remove-Variable server
Remove-Variable srv
Remove-Variable port

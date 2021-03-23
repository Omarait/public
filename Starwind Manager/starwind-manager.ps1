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
    while (!$close)
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

	# Affichage des targets et des devices rattachés
	Write-host "#################################" -foreground yellow
	Write-host "Targets and devices attached" -foreground yellow
	$global:server.Devices | Where-Object TargetId -notlike "empty" | Format-Table -AutoSize -Wrap -Property TargetId, TargetName, DeviceId, @{N='Device Name';E={$_.Name}}, @{N='Path';E={$_.File}}, @{N='Size MB';E={$_.Size/1MB}}
	
	# Affichage des targets sans device
	Write-host "#################################" -foreground yellow
	Write-host "Targets wihout devices" -foreground yellow
	$targetsToExclude = $global:server.Devices | Where-Object TargetId -notlike "empty" | Select-Object TargetId
	write-host $targetsToExclude
	$global:server.Targets | Where-Object Id -notin $targetsToExclude | Format-Table -AutoSize -Wrap -Property Id, Name
	
	# Affichage des devices attachés à aucun target
	Write-host "#################################" -foreground yellow
	Write-host "Devices not attached to a target" -foreground yellow
	$global:server.Devices | Where-Object TargetId -like "empty" | Format-Table -AutoSize -Wrap  -Property DeviceId, @{N='Device Name';E={$_.Name}}, @{N='Path';E={$_.File}}, @{N='Size MB';E={$_.Size/1MB}}
	
	Read-host "Press enter to return to menu"
}

# =======================================================
# Fonction createdevice
# Utilisation : Demande à l'utilisateur les informations pour la création d'un nouveau device et d'un nouveau target
# =======================================================

Function createdevice
{
    Clear-host
	Write-host "#################################" -foreground yellow
    Write-host "Create image file and a new target"
	# Entrée des informations du device à créer
	$filename = Read-Host "File Name"
	$path = Read-Host "Path (exemple C:\Starwind\Storage)"
	[int]$size = Read-Host "Size in MB"
	# Création du fichier
	New-ImageFile -server $global:server -path $path -fileName $filename -size $size    
	# Création du device
	Add-ImageDevice -server $global:server -path $path -fileName $filename -sectorSize 512 -NumaNode 0
	Write-host "#################################" -foreground yellow
	Read-host "Press enter to return to menu"
}

Function removedevice
{
	Clear-Host
	Write-Host "#################################" -foreground yellow
	$global:server.Devices | Where-Object TargetId -like "empty" | Format-Table -AutoSize -Wrap  -Property DeviceId, @{N='Device Name';E={$_.Name}}, @{N='Path';E={$_.File}}, @{N='Size MB';E={$_.Size/1MB}}
	write-host "#################################" -foreground yellow
	$name = Read-Host "Enter the device's name to remove"
	try {
		$devicefile = (Get-Device -server $global:server -name $name).file
		Remove-Device -server $global:server -name $name -force $true
		Remove-Item $devicefile
		write-host "#################################" -foreground yellow
		write-host "Device removed" -foreground yellow
	} catch {write-host -Foreground Red $_}
	Read-Host "Press enter to return to menu"
}

Function removetarget
{
	Clear-Host
	Write-Host "#################################" -foreground yellow
	$global:server.Targets | Format-Table -AutoSize -Wrap  -Property Id, Name
	write-host "#################################" -foreground yellow
	$name = Read-Host "Enter the target's name to remove"
	try {
		Remove-Target -server $global:server -name $name -force $true
		write-host "#################################" -foreground yellow
		write-host "Target removed" -foreground yellow
	} catch {write-host -Foreground Red $_}
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

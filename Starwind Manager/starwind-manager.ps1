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

Function startprogram {
	do {
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
		Write-host "[6] Create Target"
		Write-host "[7] Remove Target"
		Write-host "[8] Detach or Attach device to a target"
		Write-host "[9] Disconnect and close"
		Write-host "##################################" -foreground yellow
		Write-host ""
		$choice = Read-host "Enter your choice" 

		# Appel des fonctions selon le choix
		switch ($choice) {
			0 { connect_starwind }
			1 { disconnect_starwind }
			2 { enumdevices }
			3 { createdevice }
			4 { extenddevice }
			5 { removedevice }
			6 { createtarget }
			7 { removetarget }
			8 { detach_attach }
			9 { if ($global:server) { disconnect_starwind }; $close = 1 }
		}
		Clear-host
	}
	while (!$close)
}

Function connect_starwind {

	try {
		Write-host ""
		# Entrée des informations de connexions
		if (($global:srv = Read-host -Prompt "Server name or ip [default : localhost]") -eq "") { $global:srv = "localhost" }
		if (($global:port = Read-host -Prompt "Port [default : 3261]") -eq "") { $global:port = "3261" }
		if (($user = Read-host -Prompt "Username [default : root]") -eq "") { $user = "root" }
		if (($password = Read-host -Prompt "Password [default : starwind]") -eq "") { $password = "starwind" }

		# Initialisation de la connexion au serveur
		$global:server = New-SWServer $global:srv $global:port $user $password
		$global:server.Connect()
	}
	catch {
		# En cas d'erreur, afficher le message et attendre la validation
		Write-host $_ -foreground red
		Read-host "Press enter to go back"
	}
}

Function disconnect_starwind {	
	# Déconnexion du serveur
	$global:server.Disconnect()
	$global:server = $null
}

Function list_targets_and_devices_attached {
	# Affichage des targets et des devices rattachés
	$list = $global:server.Devices | Where-Object TargetId -notlike "empty" | Format-Table -AutoSize -Wrap -Property TargetId, TargetName, DeviceId, @{N = 'Device Name'; E = { $_.Name } }, @{N = 'Path'; E = { $_.File } }, @{N = 'Size MB'; E = { $_.Size / 1MB } }
	Write-host "#################################" -foreground yellow
	Write-host "Targets and devices attached" -foreground yellow
	if ($list) { $list } else { throw }
}

Function list_orphan_targets {
	# Affichage des targets sans device
	$targetsToExclude = @()
	foreach ($device in $global:server.Devices | Where-Object TargetId -notlike "empty") {
		$targetsToExclude += $device.TargetId
	}
	$list = $global:server.Targets | Where-Object Id -notin $targetsToExclude | Format-Table -AutoSize -Wrap -Property Id, Name
	Write-host "#################################" -foreground yellow
	Write-host "Targets wihout devices" -foreground yellow
	if ($list) { $list } else { throw }
}

Function list_orphan_devices {
	# Affichage des devices attachés à aucun target
	$list = $global:server.Devices | Where-Object TargetId -like "empty" | Format-Table -AutoSize -Wrap  -Property DeviceId, @{N = 'Device Name'; E = { $_.Name } }, @{N = 'Path'; E = { $_.File } }, @{N = 'Size MB'; E = { $_.Size / 1MB } }
	Write-host "#################################" -foreground yellow
	Write-host "Devices not attached to a target" -foreground yellow
	if ($list) { $list } else { throw }
}

Function list_all_devices {
	# Affichage des devices
	$list = $global:server.Devices | Format-Table -AutoSize -Wrap  -Property DeviceId, @{N = 'Device Name'; E = { $_.Name } }, @{N = 'Path'; E = { $_.File } }, @{N = 'Size MB'; E = { $_.Size / 1MB } }
	Write-host "#################################" -foreground yellow
	if ($list) { $list } else { throw }

}

Function list_all_targets {
	# Affichage des targets sans device
	$list = $global:server.Targets | Format-Table -AutoSize -Wrap -Property Id, Name
	Write-host "#################################" -foreground yellow
	if ($list) { $list } else { throw }
}

Function enumdevices {
	Clear-host
	try { list_targets_and_devices_attached } catch { Write-host "***No devices attached to a target***" -foreground red } 
	try { list_orphan_targets } catch { Write-host "***Nothing to display***" -foreground red } 
	try { list_orphan_devices } catch { Write-host "***Nothing to display***" -foreground red } 
	Read-host "Press enter to go back"
}

Function createdevice {
	Clear-host
	Write-host "#################################" -foreground yellow
	Write-host "Create image file"
	# Entrée des informations du device à créer
	$filename = Read-Host "File Name"
	$path = Read-Host "Path (exemple C:\Starwind\Storage)"
	[int]$size = Read-Host "Size in MB"
	# Création du fichier
	New-ImageFile -server $global:server -path $path -fileName $filename -size $size    
	# Création du device
	Add-ImageDevice -server $global:server -path $path -fileName $filename -sectorSize 512 -NumaNode 0
	Write-host "#################################" -foreground yellow
	$global:server.disconnect()
	$global:server.connect()
	Read-host "Press enter to go back"
}

Function removedevice {
	Clear-Host
	try { 
		list_orphan_devices
		write-host "#################################" -foreground yellow
		$id = Read-Host "Enter the device's id to remove"
		try {
			$devicefile = (Get-Device -server $global:server -id $id).file
			Remove-Device -server $global:server -DeviceId $id -force $true
			Remove-Item $devicefile
			write-host "#################################" -foreground yellow
			write-host "Device removed" -foreground yellow
		} catch { write-host -Foreground Red $_ }
		$global:server.disconnect()
		$global:server.connect()
		
	} catch { Write-host "***Nothing to display***" -foreground red } 
	Read-Host "Press enter to go back"
}

Function createtarget {
	Clear-host
	Write-host "#################################" -foreground yellow
	Write-host "Create a new target"
	# Entrée des informations du device à créer
	$alias = Read-Host "Target alias"
	try { New-Target -server $global:server -alias $alias } catch { Write-Host -Foreground Red $_ }
	Write-host "#################################" -foreground yellow
	$global:server.disconnect()
	$global:server.connect()
	Read-host "Press enter to go back"
}

Function removetarget {
	Clear-Host
	try {
		list_orphan_targets
		$name = Read-Host "Enter the target's name to remove"
		try {
			Remove-Target -server $global:server -name $name -force $true
			write-host "#################################" -foreground yellow
			write-host "Target removed" -foreground yellow
		}
		catch { write-host -Foreground Red $_ }
		$global:server.disconnect()
		$global:server.connect()
	} catch { Write-host "***Nothing to display***" -foreground red }
	Read-Host "Press enter to go back"
}

Function extenddevice {
	Clear-Host
	try {
		list_all_devices
		write-host "#################################" -foreground yellow
		$devicename = Read-Host "Device Name"
		$size = Read-Host "Size in MB"
		$device = Get-Device $global:server -name $deviceName
		try {
			$device.ExtendDevice($size)
			$global:server.disconnect()
			$global:server.connect()
			Clear-Host
			write-host "#################################" -foreground yellow
			write-host "Device extended" -foreground yellow
		} catch { write-host $_ }
	} catch { Write-host "***No devices found***" -foreground red }
	Read-Host "Press enter to go back"
}

Function detach_attach {
	Clear-Host
	write-host "#################################" -foreground yellow
	if ((Read-Host "Do you want to detach a device from a target ? [Y to execute]") -like "Y") {
		try {
			list_targets_and_devices_attached
			$targetId = Read-Host "Enter target id"
			$deviceName = Read-Host "Enter Device name"
			$target = $global:server.Targets | Where-Object Id -like $targetId
			$target.detachdevice($deviceName)
			$global:server.disconnect()
			$global:server.connect()
			Read-host "Press enter to check result"
			enumdevices
		} catch { Write-host "Nothing found" -foreground red } 
	}
	write-host "#################################" -foreground yellow
	if ((Read-Host "Do you want to attach a device from a target ? [Y to execute]") -like "Y") {
		try { 
			list_orphan_targets
			list_orphan_devices
			$targetId = Read-Host "Enter target id"
			$deviceId = Read-Host "Enter Device id"
			$target = $global:server.Targets | Where-Object Id -like $targetId
			$target.attachdevice($deviceId)
			$global:server.Disconnect()
			$global:server.Connect()
			Read-host "Press enter to check result"
			enumdevices
		} catch { Write-host "No orphan targets or Nothing to display" -foreground red }
	}
	Read-Host "Press enter to go back"
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

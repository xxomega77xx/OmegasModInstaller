function Get-ScriptDirectory
{
<#
	.SYNOPSIS
		Get-ScriptDirectory returns the proper location of the script.

	.OUTPUTS
		System.String
	
	.NOTES
		Returns the correct path within a packaged executable.
#>
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}
$scriptDirectory = Get-ScriptDirectory
$cfgPath = "$scriptDirectory\BepInEx\config\gg.reactor.api.cfg"
$pluginsPath = "$scriptDirectory\BepInEx\plugins"
$hatPackURL = 'https://github.com/xxomega77xx/HatPack/releases/latest'
$modInstallUrl = 'https://github.com/xxomega77xx/OmegasModInstaller/releases/latest'
$touURL = 'https://github.com/polusgg/Town-Of-Us/releases/latest'
$AuRegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 945360"
$modInstallerLocalVersion = (Get-Item "$scriptDirectory\OmegasModsInstaller.exe" | select -ExpandProperty VersionInfo).ProductVersion
function Get-GitHubLatestRelease ($url)
{
	$request = [System.Net.WebRequest]::Create($url)
	$response = $request.GetResponse()
	$realTagUrl = $response.ResponseUri.OriginalString
	$version = $realTagUrl.split('/')[-1].Trim('v')
	return $version
}
$GHhatPackVersion = Get-GitHubLatestRelease -url $hatPackURL
$GHtouVersion = Get-GitHubLatestRelease -url $touURL
$modInstallServerVersion = Get-GitHubLatestRelease -url $modInstallUrl

$FullConfigFileValue = @"
## Settings file was created by plugin Reactor v1.0.0-rc.1
## Plugin GUID: gg.reactor.api

[Features]

## Whether reactor should ignore servers not responding to modded handshake. This config is ignored if any plugin uses custom rpcs!
# Setting type: Boolean
# Default value: false
Allow vanilla servers = true
"@
function Invoke-StartUp ()
{
	try
	{
		write "Checking if you own a legal copy of Among Us"
		if (Test-Path -Path $AuRegKey)
		{
			write " Yay your legal!!"
		}
		else
		{
			write " Opps better go buy a valid copy"
			exit
		}
		Write "Checking for Installer updates..."
		if ($modInstallerLocalVersion -eq $modInstallServerVersion)
		{
			write "You are up to date, Your Version : $modInstallerLocalVersion"
			write "Server version $modInstallServerVersion"
		}
		else
		{
			write "Updating Your Current Version to : $modInstallServerVersion"
			write "Your version $modInstallerLocalVersion"
			Start-Process $scriptDirectory\Updater.exe -Wait
		}
		write "Checking for correct exe location..."
		if ((Test-Path -Path $pluginsPath) -and (Test-Path -Path "$scriptDirectory\Among Us.exe"))
		{
			write " EXE is in the correct location, Awesome Job!!!"
			if (!(Test-Path -Path $scriptDirectory\Temp))
			{
				$null = New-Item -Path $scriptDirectory\Temp -ItemType Directory
			}
		}
		else
		{
			write "Checking if fresh modded install folder"
			if (!(Get-Item -Path "$scriptDirectory\Among Us.exe").DirectoryName.Contains("Steam"))
			{
				write "We are fresh moving on..."
				if (!(Test-Path -Path $scriptDirectory\Temp))
				{
					$null = New-Item -Path $scriptDirectory\Temp -ItemType Directory
				}
			}
			else
			{
				write "  EXE needs to be in the Modded folder place it there and re-run the script"
				write "  Your current directory is $scriptDirectory"
				Read-Host "Press enter to continue"
				exit
			}
			
		}
		write "Checking to make sure Among us isn't running..."
		if (Get-Process -Name 'Among Us' -ErrorAction SilentlyContinue)
		{
			write "  Among Us is currently running, forcing it closed to install properly."
			Stop-Process -Name 'Among Us' -Force
			write "Among Us closed."
		}
		else
		{
			write "Among Us is not running continuing on"
		}
		Write-Host "*********************************************" -ForegroundColor Green
		write-host "Welcome to Omegas Mod Installer" -ForegroundColor Green
		write-host "please make a selection below" -ForegroundColor Green
		Write-Host "*********************************************" -ForegroundColor Green
		write-host "1. Install Hatpack" -ForegroundColor Green
		write-host "2. Install Town of Us" -ForegroundColor Green
		write-host "3. Install Hatpack and Town of Us" -ForegroundColor Green
		write-host "4. Create Modded from Scratch" -ForegroundColor Green
		write-host "5. Exit" -ForegroundColor Green
		$selection = Read-Host "Enter Selection"
		Write-Host "*********************************************" -ForegroundColor Green
		switch ($selection) {
			1 {
				Install-Hatpack
			}
			2 {
				Install-ToU
			}
			3 {
				Install-ToU
				Install-Hatpack
			}
			4 {
				Create-ModdedFoldersandFiles
				Install-ToU
				Install-Hatpack
			}
			default {
				Read-Host "Please make a selection press enter to try again"
				Invoke-StartUp
			}
		}
	}
	catch
	{
		write "An Error Occured : $($psitem.exception.message)"
	}
	
}

function Create-ModdedFoldersandFiles ()
{
	$auRegKeyProperties = Get-ItemProperty -Path $AuRegKey
	$installLocation = $auRegKeyProperties.InstallLocation
	$currentUserDesktopPath = "$env:USERPROFILE\Desktop"
	$AuDesktopDirectoryPath = "$currentUserDesktopPath\AmongUsModded"
	$null = New-Item -Path $AuDesktopDirectoryPath -ItemType Directory
	Copy-Item -Path $installLocation -Destination $AuDesktopDirectoryPath
}
function Install-Hatpack ()
{
	if (Test-Path -Path $pluginsPath)
	{
		write "Checking config file..."
		try
		{
			
			if (Test-Path -Path $cfgPath)
			{
				$cfg = get-content -Path $cfgPath
				$cfgValue = $cfg | Select-String -Pattern "Allow vanilla"
				if ($cfgValue.ToString() -eq "Allow vanilla servers = false")
				{
					Write "  Setting Config"
					$cfg -replace "Allow vanilla servers = false", "Allow vanilla servers = true" | Set-Content -Path $cfgPath
					write "Config set"
				}
				else
				{
					Write "Config is properly set"
				}
			}
			else
			{
				Write "Config file does not exist creating config file..."
				try
				{
					New-Item -Path $cfgPath -Value $FullConfigFileValue | Out-Null
					write "Config file created successfully."
				}
				catch
				{
					write "An Error Occurred : $($psitem.exception.message)"
				}
				
			}
		}
		catch
		{
			write "Error Occurred : $($psitem.exception.message)"
		}
		if (Test-Path -Path $pluginsPath\hatpack.dll)
		{
			
			$hatPackVersion = (Get-Item $pluginsPath\HatPack.dll | select -ExpandProperty VersionInfo).ProductVersion
			Write "Checking version of hatpack..."
			write "Server version is $GHhatPackVersion"
			if ($GHhatPackVersion -eq $hatPackVersion)
			{
				Write "Hatpack is up to date current installed version = $hatPackVersion"
			}
			else
			{
				Remove-Item -Path $pluginsPath\hatpack.dll -Force
				Write "Updating Hatpack..."
				Invoke-WebRequest -Uri https://github.com/xxomega77xx/HatPack/releases/download/v$GHhatPackVersion/HatPack.dll -OutFile $pluginsPath\Hatpack.dll
				write "Hatpack updated"
			}
		}
		else
		{
			write "Server version is $GHhatPackVersion"
			write "Installing Hatpack..."
			try
			{
				Invoke-WebRequest -Uri https://github.com/xxomega77xx/HatPack/releases/download/v$GHhatPackVersion/HatPack.dll -OutFile $pluginsPath\Hatpack.dll
				write "HatPack Installed"
			}
			catch
			{
				write "An Error Occurred : $($psitem.exception.message)"
			}
			
			write "Installing Reactor..."
			try
			{
				Invoke-WebRequest -Uri https://github.com/xxomega77xx/HatPack/releases/download/v$GHhatPackVersion/Reactor.dll -OutFile $pluginsPath\Reactor.dll
				write "Reactor Installed"
			}
			catch
			{
				write "An Error Occurred : $($psitem.exception.message)"
			}
			
		}
	}
	else
	{
		$bepInExZip = (Invoke-RestMethod -Uri "https://api.github.com/repos/xxomega77xx/HatPack/releases").assets.browser_download_url[0]
		write "No other mods Installed downloading required files..."
		Invoke-WebRequest -Uri $bepInExZip -OutFile $scriptDirectory\Temp\BepInEx.zip
		Expand-Archive -Path $scriptDirectory\Temp\BepInEx.zip -DestinationPath $scriptDirectory\Temp -Force
		$null = Move-Item -Path $scriptDirectory\Temp\* -Exclude *.zip -Destination $scriptDirectory
		Install-Hatpack
		
	}
	
}
function Install-ToU ()
{
	$latestTouReleaseURL = (Invoke-RestMethod -Uri "https://api.github.com/repos/polusgg/Town-Of-Us/releases").assets.browser_download_url[0]
	if (Test-Path -Path $pluginsPath\TownOfUs.dll)
	{
		
		$touVersion = (Get-Item $pluginsPath\TownOfUs.dll | select -ExpandProperty VersionInfo).ProductVersion
		if ($GHtouVersion -eq $touVersion)
		{
			write "Town of Us is up to date Current version = $touVersion"
		}
		else
		{
			write "Updating Town of Us to $GHtouVersion"
			if (Test-Path -Path $pluginsPath\TownOfUs.dll)
			{				
				Remove-Item -Path $pluginsPath\TownOfUs.dll -Force
			}
			Invoke-WebRequest -Uri $latestTouReleaseURL -OutFile $scriptDirectory\Temp\TownOfUs$GHtouVersion.zip
			Expand-Archive -Path $scriptDirectory\Temp\TownOfUs$GHtouVersion.zip -DestinationPath $scriptDirectory\Temp -Force
			$null = Move-Item -Path $scriptDirectory\Temp\BepInEx\plugins\TownofUs.dll -Destination $pluginsPath
		}
	}
	else
	{
		try
		{			
			write "Downloading TOU version $GHtouVersion"
			Invoke-WebRequest -Uri $latestTouReleaseURL -OutFile $scriptDirectory\Temp\TownOfUs$GHtouVersion.zip
			Expand-Archive -Path $scriptDirectory\Temp\TownOfUs$GHtouVersion.zip -DestinationPath $scriptDirectory\Temp -Force
			if (Test-Path $pluginsPath)
			{
				Move-Item -Path $scriptDirectory\Temp\BepInEx\plugins\TownOfUs.dll -Destination $pluginsPath
			}
			else
			{
				Move-Item -Path $scriptDirectory\Temp\* -Destination $scriptDirectory -Exclude "*.zip" -Force
			}
			
		}
		catch
		{
			write "An Error Occurred $($psitem.exception.message)"
		}
	}
}
Invoke-StartUp

Read-Host "Script complete press enter to close"
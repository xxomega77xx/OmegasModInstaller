#Updates and moves OmegasModInstall.ps1
function Get-GitHubLatestRelease ($url)
{
	$request = [System.Net.WebRequest]::Create($url)
	$response = $request.GetResponse()
	$realTagUrl = $response.ResponseUri.OriginalString
	$version = $realTagUrl.split('/')[-1].Trim('v')
	return $version
}
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
$modInstallerServerVersionLatest = 'https://github.com/xxomega77xx/OmegasModInstaller/releases/latest'
$modInstallerLocalVersion = (Get-Item "$scriptDirectory\OmegasModsInstaller.exe" | select -ExpandProperty VersionInfo).ProductVersion
$modInstallerServerVersion = Get-GitHubLatestRelease -url $modInstallerServerVersionLatest
$currentUserDesktopPath = "$env:USERPROFILE\Desktop"
$AuDesktopDirectoryPath = "$currentUserDesktopPath\AmongUsModded"

Try
{
	write "Stoping Mod Installer process for tasks..."
	Stop-Process -Name OmegasModsInstaller -Force -ErrorAction Ignore
	if (($modInstallerLocalVersion -eq $modInstallerServerVersion) -and ($AuDesktopDirectoryPath -ne $scriptDirectory))
	{
		write "Copying Mod Installer to new modded folder"
		Copy-Item -Path $scriptDirectory\OmegasModsInstaller.exe -Destination $AuDesktopDirectoryPath -Force
		write "Copy complete"
		write "Starting Mod installer from correct folder"
		Start-Process $AuDesktopDirectoryPath\OmegasModsInstaller.exe
		exit
	}
	write "Updating Omegas Mod Installer..."
	$modInstallerLocalVersion -eq $modInstallerServerVersion
	$AuDesktopDirectoryPath -ne $scriptDirectory
	Invoke-WebRequest -Uri https://github.com/xxomega77xx/OmegasModInstaller/releases/download/v$modInstallerServerVersion/OmegasModsInstaller.exe -OutFile $scriptDirectory\OmegasModsInstaller.exe
	Write "Updated Successfully"
}
catch
{
	write "Update Error : $($psitem.exception.message)"
}
Read-Host "Press enter to continue"

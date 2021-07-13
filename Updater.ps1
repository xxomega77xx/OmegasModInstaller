#Updates and moves OmegasModInstall.ps1
function Get-GitHubLatestRelease ($url)
{
	$request = [System.Net.WebRequest]::Create($url)
	$response = $request.GetResponse()
	$realTagUrl = $response.ResponseUri.OriginalString
	$version = $realTagUrl.split('/')[-1].Trim('v')
	$response.Close()
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
$global:scriptDirectory = Get-ScriptDirectory
$global:modInstallerServerVersionLatest = 'https://github.com/xxomega77xx/OmegasModInstaller/releases/latest'
$global:modInstallerLocalVersion = (Get-Item "$scriptDirectory\OmegasModsInstaller.exe" | select -ExpandProperty VersionInfo).ProductVersion
$global:modInstallerServerVersion = Get-GitHubLatestRelease -url $modInstallerServerVersionLatest
$global:currentUserDesktopPath = "$env:USERPROFILE\Desktop"
$global:AuDesktopDirectoryPath = "$currentUserDesktopPath\AmongUsModded"

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
	Invoke-WebRequest -Uri https://github.com/xxomega77xx/OmegasModInstaller/releases/download/v$modInstallerServerVersion/OmegasModsInstaller.exe -OutFile $scriptDirectory\OmegasModsInstaller.exe
	Write "Updated Successfully"
}
catch
{
	write "Update Error : $($psitem.exception.message)"
}
Read-Host "Press enter to continue"

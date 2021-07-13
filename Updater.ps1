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
$modInstallerServerVersionLatest = 'https://github.com/xxomega77xx/OmegasModInstaller/releases/latest'
$scriptDirectory = Get-ScriptDirectory
Try
{
	write "Updating Omegas Mod Installer..."
	Stop-Process -Name OmegasModsInstaller.exe -Force
	Invoke-WebRequest -Uri https://github.com/xxomega77xx/OmegasModInstaller/releases/download/v$modInstallerServerVersionLatest/OmegasModsInstaller.exe -OutFile $scriptDirectory\OmegasModInstaller.exe
	Write "Updated Successfully"
}
catch
{
	write "Update Error : $($psitem.exception.message)"
}

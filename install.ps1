#
# This script will install module in Powershell modules localization.
# Install means copy files from repo to $env:ProgramFiles\WindowsPowerShell\Modules\$moduleName"
#
$moduleName = "Bendev.Assets.Management"
$projectFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
$solutionFolder = Split-Path -Parent $projectFolder
#$modulePath = Join-Path $projectFolder -ChildPath $moduleName 
#$modulePath = "$moduleName"
$modulePath = "$projectFolder"


#region Install module"

$targetPath = Join-Path $env:ProgramFiles -ChildPath "\WindowsPowerShell\Modules\$moduleName"

if( -not (Test-Path -Path $targetPath))
{
	md $targetPath
}

Write-Output "SolutionFolder:" $solutionFolder
Write-Output "ProjectFolder:" $projectFolder
Write-Output "Source: $modulePath"
Write-Output "Path: $targetPath"

Remove-Item "$targetPath\*" -Verbose -Recurse -Force


md "$targetPath\classes" -Force 
$filesToExclude = @( "install.ps1", "Tests", "*.tests.ps1")

Copy-Item -Path $modulePath\* -Destination "$targetPath" -Include *.psd1, *.psm1, *.ps1, *.md -Exclude $filesToExclude   -Force -Verbose -Recurse 
Copy-Item -Recurse -Path $modulePath\classes\* -Destination "$targetPath\classes" -Include *.psd1, *.psm1, *.ps1 -Exclude $filesToExclude -Force -Verbose

#endregion
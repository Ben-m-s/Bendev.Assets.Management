<#
Example of Assets definition file:

    .\Tests\ConfigSamples\Assets2.json

Examples of PowerShell Transformations:

   .\Tests\Transforms\sitecore-xp0.ps1
   .\Tests\Transforms\xconnect-xp0.ps1

   Each transformation should be simple and specific to the transformed file.
   They are always provided with the path to the source file and the path where the output should be stored.
#>

$projectFolder = Split-Path -Parent $MyInvocation.MyCommand.Path

#Import-Module Bendev.Assets.Management -Force -Verbose
#Import-Module –Name $projectFolder -Force -Verbose

$assetsDefinitionFilePath = (Join-Path $projectFolder 'ConfigSamples\Assets2.json'); # Sample 2

$AssetsSourcePath = 'h:\Software\Sitecore\Repository'; # This path must contain the assets specified at root level in the assets definition files (*.json)

$AssetsTransformPath = $null; # In case we want to apply transformation in an alternative path (useful when paths get too long after decompression). Defaults $AssetsSourcePath
$targetPath = (Join-Path $projectFolder 'Results\'); # Location where the final assets (those without any transform) will be saved.
$transformationsSourcePath = $projectFolder; # used with Tranformation: PowerShellScriptTransform

if (Test-Path $assetsDefinitionFilePath -PathType Leaf) {
   $data = Get-Content -Path $assetsDefinitionFilePath | ConvertFrom-Json
   $assets = [Asset]::ParseArray(@($data.assets))

   Write-Host "Start: Processing assets";

   # Copy any missing asset into build context
   if ($assets){
       #Debugging:
       Invoke-ProcessAssets $assets $AssetsSourcePath $targetPath $AssetsTransformPath $transformationsSourcePath
   }
   Write-Host "End: Processing assets";

}
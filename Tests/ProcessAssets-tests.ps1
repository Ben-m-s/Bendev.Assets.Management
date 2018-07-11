<#
Examples of Assets definition files:

    .\Tests\InputSamples\Assets1.json
    .\Tests\InputSamples\Assets2.json

Examples of PowerShell Transformations:

   .\Tests\Transforms\sitecore-XM1-cm.ps1
   .\Tests\Transforms\sitecore-xp0.ps1
   .\Tests\Transforms\xconnect-xp0.ps1

   Each transformation should be simple and specific to the transformed file.
   They are always provided with the path to the source file and the path where the output should be stored.
   Additional parameters can be provided through the json file. See example "sitecore-XM1-cm.ps1"
#>

$projectFolder = Split-Path -Parent $MyInvocation.MyCommand.Path

$assetsDefinitionFilePath = (Join-Path $projectFolder 'InputSamples\Assets1.json'); # Sample 1
#$assetsDefinitionFilePath = (Join-Path $projectFolder 'InputSamples\Assets2.json'); # Sample 2

$AssetsSourcePath = 'h:\Software\Sitecore\Repository'; # This path must contain the assets specified at root level in the assets definition files (*.json)

$AssetsTransformPath = $null; # In case we want to apply transformation in an alternative path (useful when paths get too long after decompression). Defaults $AssetsSourcePath
$targetPath = (Join-Path $projectFolder 'Results\'); # Location where the final assets (those without any transform) will be saved.
$transformationsSourcePath = $projectFolder; # used with Tranformation: PowerShellScriptTransform

if ([String]::IsNullOrWhiteSpace($AssetsTransformPath)){
   $AssetsTransformPath = $AssetsSourcePath;
}

if (Test-Path $assetsDefinitionFilePath -PathType Leaf) {
   $data = Get-Content -Path $assetsDefinitionFilePath | ConvertFrom-Json
   $assets = [Asset]::ParseArray(@($data.assets))

   Write-Host "Start: Processing assets";

   # Copy any missing asset into build context
   if ($assets){
       #Debugging:
       Invoke-ProcessAssets $assets $AssetsSourcePath $AssetsTransformPath $targetPath $transformationsSourcePath
   }
   Write-Host "End: Processing assets";

}
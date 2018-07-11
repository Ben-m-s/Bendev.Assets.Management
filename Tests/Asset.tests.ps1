<#---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------#>

$projectFolder = Split-Path -Parent $MyInvocation.MyCommand.Path

#Import-Module Bendev.Assets.Management -Force -Verbose
#Import-Module –Name $projectFolder -Force -Verbose


$input1 = "License.xml"
$input2 = New-Object –TypeName PSObject `
            -Property @{
                Path = "Sitecore 9.0.1 rev. 171219 (WDP XP0 packages).zip";
                Transforms = @(
                    New-Object –TypeName PSObject `
                        -Property @{
                            Type = "UnzipTransform";
                            Properties = @{
                                TargetPath = "Sitecore 9.0.1 rev. 171219 (WDP XP0 packages)"
                                     }
                         }
                )
             }
$input3 = @{
            Path = "Sitecore 9.0.1 rev. 171219 (WDP XP0 packages).zip";
            Transforms = @(
                    @{
                        Type = "UnzipTransform";
                        TargetPath = "Sitecore 9.0.1 rev. 171219 (WDP XP0 packages)"
                     }
                )
             }
$input4 = @{
            Path = "Sitecore 9.0.1 rev. 171219 (WDP XP0 packages).zip";
            Transforms = @( # Array
                    @{ # Object (Hastable)
                        Type = "UnzipTransform";
                        ConstructorArgs = @(); # Array
                        Properties = @{ # Object (Hastable)
                            TargetPath = "Sitecore 9.0.1 rev. 171219 (WDP XP0 packages)"
                        }
                     }
                )
             }
$input5 = @{
            Path = "Sitecore 9.0.1 rev. 171219 (WDP XP0 packages).zip";
            Transforms = @( # Array
                    @{ # Object (Hastable)
                        Type = "UnzipTransform";
                     }
                )
             }


[Asset[]]$assets = [Asset]::ParseArray(@($input1, $input2, $input3, $input4, $input5));
$assets | ForEach-Object {
    $a = $_
    Write-Host "$a"
    if ($a.Transforms) {$a.Transforms | ForEach-Object {$_.Execute([TransformExecutionArgs]::New("H:\\Software\\Sitecore\\Repository", "H:\\Software\\Sitecore\\Repository", (Join-Path $projectFolder "FunPath")))}}
}

ConvertTo-Json $assets -Depth 50 | Set-Content -Path (Join-Path $projectFolder "Results\\AssetTestsOutput.json"); 

[Asset]$asset = [Asset]::Parse($input1);
Write-Host "$asset"

#[Transform] $transform = [Transform](New-Object -TypeName "UnzipTransform")
#$transform.Execute([TransformExecutionArgs]::New("aaa", "bbb", "ccc"))
#[Asset]$asset = [Asset]::New("Tests", @($transform))

#Write-Host "$asset"
#if ($asset.Transforms) {$asset.Transforms | ForEach-Object {$_.Execute([TransformExecutionArgs]::New("aaa", "bbb", "ccc"))}}


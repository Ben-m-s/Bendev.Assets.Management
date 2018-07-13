function Invoke-ProcessAssets{
	param(
		[Parameter(Mandatory = $true)]
        [Asset[]]$Assets, 
		[Parameter(Mandatory = $true)]
		[ValidateScript( {Test-Path $_ -PathType 'Container'})] 
        [String]$AssetsSourcePath, 
		[Parameter(Mandatory = $true)]
		[ValidateScript( {Test-Path $_ -PathType 'Container'})] 
        [String]$TargetPath, 
		[Parameter(Mandatory = $false)]
		[ValidateScript( {[String]::IsNullOrWhiteSpace($AssetsTransformPath) -or (Test-Path $_ -PathType 'Container')})] 
        [String]$AssetsTransformPath, 
		[Parameter(Mandatory = $false)]
		[ValidateScript( {Test-Path $_ -PathType 'Container'})] 
        [string]$PSTransformationsSourcePath
    )

    if ([String]::IsNullOrWhiteSpace($AssetsTransformPath)){
       $AssetsTransformPath = $AssetsSourcePath;
    }

	$Assets | ForEach-Object {
		$assetMetadata = $_;
        $assetPath = Join-Path $AssetsSourcePath $assetMetadata.SourcePath;
        $transformArgs = [TransformExecutionArgs]::new($assetPath, $AssetsTransformPath, $PSTransformationsSourcePath)
        if($assetMetadata.Transforms){
            $assetMetadata.Transforms | ForEach-Object{
                $transform = $_;
                #if ($transform){ $transform.Execute(($transformArgs));}
                $transform.Execute(($transformArgs));
                $assetPath = $transformArgs.AssetPath;# The asset path may have changed in the transform
            }
        }
		if ($assetMetadata.Assets){
            Invoke-ProcessAssets $assetMetadata.Assets $transformArgs.AssetPath $TargetPath $transformArgs.TransformPath $PSTransformationsSourcePath
		}

        [Boolean]$shouldCopy = (($assetMetadata.CopyMode -eq [CopyMode]::Copy) -Or (-Not $assetMetadata.Assets));
        if($shouldCopy){
		    $assetItem = Get-Item -Path $assetPath;

            if ($assetMetadata.TargetPath){
    		    $destinationFolder = Join-Path $TargetPath $assetMetadata.TargetPath
            }else{
    		    $destinationFolder = $TargetPath
            }

			#Copy-Item $assetItem -Destination $newTargetPath -Verbose:$VerbosePreference -Recurse -Force
            #$destinationFolder = $newTargetPath.Replace($newTargetPath.Split("\")[-1],"")
            if (!(Test-Path -path $destinationFolder)) {
                New-Item $destinationFolder -Type Directory
            }

    		$newTargetPath = Join-Path $destinationFolder $assetItem.Path
			Write-Host "Copying '$assetPath' to '$newTargetPath'"

			Copy-Item $assetPath $newTargetPath -Verbose:$VerbosePreference -Recurse -Force
        }

	}
}
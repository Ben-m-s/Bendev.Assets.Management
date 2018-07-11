function Invoke-ProcessAssets([Asset[]]$assets, [String]$AssetsSourcePath, [String]$AssetsTransformPath, [String]$targetPath, [string]$imagePath){
	$assets | ForEach-Object {
		$assetMetadata = $_;
        $assetPath = Join-Path $AssetsSourcePath $assetMetadata.SourcePath;
        $transformArgs = [TransformExecutionArgs]::new($assetPath, $AssetsTransformPath, $imagePath)
        if($assetMetadata.Transforms){
            $assetMetadata.Transforms | ForEach-Object{
                $transform = $_;
                #if ($transform){ $transform.Execute(($transformArgs));}
                $transform.Execute(($transformArgs));
                $assetPath = $transformArgs.AssetPath;# The asset path may have changed in the transform
            }
        }
		if ($assetMetadata.Assets){
            Invoke-ProcessAssets $assetMetadata.Assets $transformArgs.AssetPath $transformArgs.TransformPath $targetPath $imagePath
		}

        [Boolean]$shouldCopy = (($assetMetadata.CopyMode -eq [CopyMode]::Copy) -Or (-Not $assetMetadata.Assets));
        if($shouldCopy){
		    $assetItem = Get-Item -Path $assetPath;

            if ($assetMetadata.TargetPath){
    		    $destinationFolder = Join-Path $targetPath $assetMetadata.TargetPath
            }else{
    		    $destinationFolder = $targetPath
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
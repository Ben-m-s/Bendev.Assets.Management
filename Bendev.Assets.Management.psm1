enum CopyMode{
    Default = 0 # The asset will be copied only if it has no sub-assets
    Copy = 1 # The asset will be copied regardless of not having sub-assets
    Skip = 2 # The asset will not be copied regardless of having sub-assets
}

class TransformExecutionArgs{
    [string]$AssetPath
	[string]$TransformPath
	[string]$ImagePath

    TransformExecutionArgs([string]$assetPath, [string]$transformPath, [string]$imagePath){
        $this.AssetPath = $assetPath;
	    $this.TransformPath = $transformPath;
	    $this.ImagePath = $imagePath;
    }
}

class Transform {

    [String]$TargetPath;

    [void] Execute([TransformExecutionArgs]$data){
        
        Write-Host "No transformation performed"
    }

    Transform (){
        
        
    }
}

class Asset {

    [String]$SourcePath;
    [Transform[]]$Transforms;
    [Asset[]]$Assets;
    [String]$TargetPath;
    [CopyMode]$CopyMode = [CopyMode]::Default;

    static [Asset[]]ParseArray([Array] $objs){
        $newAssets = New-Object "System.Collections.Generic.List[Asset]"
        $objs | ForEach-Object{
            [Asset]$newObj = $null;
            $obj = $_;
            if ($obj -is [string]){
                $newObj = [Asset]::Parse([string]$obj);
                $newAssets.Add($newObj);
            }elseif($obj -is [PsObject]){
                $newObj = [Asset]::Parse([PsObject]$obj);
                $newAssets.Add($newObj);
            }else{
                throw [System.NotSupportedException] "Not supported object type"
            }

        }
        return $newAssets.ToArray();
    }
    static [Asset]Parse([String] $obj){
        [Asset]$newObj = [Asset]::New($obj, [string]$null);
        return $newObj;
    }
    static [Asset]Parse([PsObject] $obj){
        [Asset]$newObj = $null;

        $trfms = New-Object "System.Collections.Generic.List[Transform]"
        if ($obj.Transforms){
            $obj.Transforms | ForEach-Object {
                $transformDef= $_;
                $type = 'Transform';
                if ($transformDef.Type){
                    $type = $transformDef.Type;
                    if($transformDef -is [System.Collections.IDictionary]){
                        $transformDef.Remove("Type");
                    }
                }
                [Object[]]$args = $null
                if ($transformDef.ConstructorArgs){
                    $args = $transformDef.ConstructorArgs;
                    if($transformDef -is [System.Collections.IDictionary]){
                        $transformDef.Remove("ConstructorArgs")
                    }
                }
                [System.Collections.IDictionary]$props = $null;
                if ($transformDef.Properties){
                    $props = $transformDef.Properties;
                    if($transformDef -is [System.Collections.IDictionary]){
                        $transformDef.Remove("Properties");
                    }
                }else{
                    if($transformDef -is [System.Collections.IDictionary]){
                        $props = $transformDef;
                    }else{
                        $props = [System.Collections.Generic.Dictionary[String, Object]]::new();
                        $transformDef.PSObject.Properties | ForEach-Object {
                            $prp = $_;
                            switch($prp.name){
                                Type{}
                                ConstructorArgs{}
                                Properties{}
                                default{
    	    	                    $props.Add($prp.name, $prp.value);
                                }
                            }
			            }
                    }
                }
                [Transform]$transform = [Transform](New-Object -TypeName $type -ArgumentList $args -Property $props);
                $trfms.Add($transform);
            }
        }
        [Asset[]]$subAssets= $null
        if ($obj.Assets){
            $subAssets = [Asset]::ParseArray($obj.Assets);
        }

        [String]$tPath = $null;
        if($obj.TargetPath){
            $tPath = $obj.TargetPath
        }
        
        [CopyMode]$tmpCopyMode = [CopyMode]::Default;
        if ($obj.CopyMode){
            $tmpCopyMode = $obj.CopyMode;
        }

        $newObj = [Asset]::New($obj.SourcePath, $trfms.ToArray(), $subAssets, $tPath, $tmpCopyMode);

        return $newObj;
    }

    [string]ToString(){
        return $this.SourcePath
    }

    Asset ([String]$sourcePath, [String]$targetPath){
        $this.SourcePath = $sourcePath;
        $this.TargetPath = $targetPath;
    }
    Asset ([String]$sourcePath, [Transform[]]$transforms, [Asset[]]$assets, [String]$targetPath, [CopyMode]$copyMode){
        $this.SourcePath = $sourcePath
        $this.Transforms = $transforms
        $this.Assets = $assets
        $this.TargetPath = $targetPath;
        $this.CopyMode = $copyMode;
    }
}

class PowerShellScriptTransform: Transform{

    [String]$PSScript;
    [PSObject]$AdditionalParameters;

    [void] Execute([TransformExecutionArgs]$data){

        $assetPath = $data.AssetPath;        
        $transformPath = $data.TransformPath;        
        if ($this.TargetPath){
            if ([System.IO.Path]::IsPathRooted($this.TargetPath)){
                $transformPath = $this.TargetPath
            }else{
                $transformPath = (Join-Path $transformPath $this.TargetPath)
            }
        }
        $scriptPath = (Join-Path $data.ImagePath $this.PSScript)

        $data.AssetPath = $transformPath;
        $data.TransformPath = $transformPath;

        Write-Host "Transforming the JSON file '$assetPath' into '$transformPath' using '$scriptPath'" -ForegroundColor Green

        $exp = "&`"$scriptPath`" -SourcePath `"$assetPath`" -TargetPath `"$transformPath`""

		# Additional parameters can be passed from the JSON file as follows:
		# "AdditionalParameters": {"Param1":"aaa", "Param2":"bbb"}
        if($this.AdditionalParameters){
            $this.AdditionalParameters.PSObject.Properties | ForEach-Object {
                $prp = $_;
                $exp = "{0} -{1} `"{2}`"" -f $exp, $prp.Name, $prp.Value
            }
        }
        #Write-Host $exp

        Invoke-Expression $exp

		#$assetItem = Get-Item -Path $assetPath;
		#Copy-Item $assetItem -Destination $transformPath
        
        Write-Host "Transformed JSON file '$assetPath' into '$transformPath'" -ForegroundColor Green

    }

    PowerShellScriptTransform () : base (){
        
        
    }
}

class UnzipTransform: Transform{

    [void] Execute([TransformExecutionArgs]$data){

        $assetPath = $data.AssetPath;        
        $transformPath = $data.TransformPath;        
        if ($this.TargetPath){
            if ([System.IO.Path]::IsPathRooted($this.TargetPath)){
                $transformPath = $this.TargetPath
            }else{
                $transformPath = (Join-Path $transformPath $this.TargetPath)
            }
        }
        $data.AssetPath = $transformPath;
        $data.TransformPath = $transformPath;

		if (!(Test-Path -Path $transformPath)) {
            Expand-Archive -Path $assetPath -DestinationPath $transformPath;
            Write-Host "Unzipped $assetPath into $transformPath" -ForegroundColor Green
		}else{
            Write-Host "Not need to unzip asset $assetPath. Destination '$transformPath' already exists" -ForegroundColor Green
        }

    }

    UnzipTransform () : base (){
        
        
    }
}

class DotNetUnzipTransform: Transform{

    [Boolean]$Overwrite = $false;

    [void] Execute([TransformExecutionArgs]$data){

        $assetPath = $data.AssetPath;        
        $transformPath = $data.TransformPath;        
        if ($this.TargetPath){
            if ([System.IO.Path]::IsPathRooted($this.TargetPath)){
                $transformPath = $this.TargetPath
            }else{
                $transformPath = (Join-Path $transformPath $this.TargetPath)
            }
        }
        $data.AssetPath = $transformPath;
        $data.TransformPath = $transformPath;

        Invoke-EnsureDirectoryExists $transformPath

        Get-ChildItem -Path $assetPath | ForEach-Object {
            $zipPath = $_.FullName
            $maxPathSize = 260

            try
            {
                $stream = New-Object IO.FileStream($zipPath, [System.IO.FileMode]::Open)
                $zip = New-Object IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Read)

                #[System.IO.Compression.ZipFileExtensions]::ExtractToDirectory($zip, $transformPath)
        
                <#
                #>
                $zip.Entries | Foreach-Object {
                  if ($_.FullName.EndsWith('/')){
                        Invoke-EnsureDirectoryExists (Join-Path $transformPath $_.FullName);
                    }else{
                        $filePath = (Join-Path $transformPath $_.FullName)
                        $parentDirectory = [System.IO.Path]::GetDirectoryName($filePath)
                        if ($filePath.Length -gt $maxPathSize){
                            Write-Host "Too long Path ($filePath.Length): $filePath" -ForegroundColor Red
                        }else{
                            Invoke-EnsureDirectoryExists $parentDirectory;
                            #Write-Host "Decompressing: $filePath"
                            #[IO.Compression.ZipFileExtensions]::ExtractToFile($_, $filePath , $this.Overwrite)

                            if ( (-Not $this.Overwrite) -And (Test-Path $filePath)){
                                Write-Host "Already Exists: $filePath"
                            }else{
                                Write-Host "Overwriting: $filePath"
                                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $filePath , $true)
                            }
                        }
                    }
                }
            }
            finally
            {
                if ($zip -ne $null)
                {
                    $zip.Dispose()
                }

                if ($stream -ne $null)
                {   
                    $stream.Dispose()
                }
            }
        }
    }

    DotNetUnzipTransform () : base (){
        
        
    }
}


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
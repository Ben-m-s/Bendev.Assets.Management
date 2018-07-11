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

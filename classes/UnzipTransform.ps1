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
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

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
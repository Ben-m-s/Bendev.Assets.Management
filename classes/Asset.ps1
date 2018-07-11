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


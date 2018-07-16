# Bendev Assets Management

The Bendev Assets Management is a light-weight PowerShell module that takes one or more files as input, transforms them and saves the result in the specified folder/s. It can be used to automate the processing of files within other processes driven with PowerShell.

It provides a few, although powerful, transformations out of the box, and it can be easily extended to fulfil more requirements.

The original purpose to design the module was to assist in the installation of [Sitecore](https://www.sitecore.com) within a [Docker](https://www.docker.com/) container. The module allows to decompress zip files that are embedded inside of other Zip files (the original Sitecore installation packages) and transforms them before copying them to the Docker container/image. The result is a smaller container and a faster process to build it.

The Bendev Assets Management detects whether the source files have already been decompressed, and skips the decompression if it is not necessary, reducing this way its execution time.

Beside its original objective, the Bendev Assets Management module can be used for other processes that require the transformation of files which are nested (zipped) within other. Additional PowerShell scripts can be defined and embedded in any part of the transformation process.

## How does it work?

The basic code required to trigger a transformation is as follows:

    $data = Get-Content -Path $assetsDefinitionFilePath | ConvertFrom-Json
    $assets = [Asset]::ParseArray(@($data.assets))
    Invoke-ProcessAssets $assets $AssetsSourcePath $AssetsTransformPath $targetPath $transformationsSourcePath

Firstly, the configuration data is loaded as text:

    $data = Get-Content -Path $assetsDefinitionFilePath | ConvertFrom-Json

The JSON data is parsed as an [Asset] object. 

    $assets = [Asset]::ParseArray(@($data.assets))

Finally, the cmdlet Invoke-ProcessAssets takes care of everything else.

    Invoke-ProcessAssets $assets $AssetsSourcePath $AssetsTransformPath $targetPath $transformationsSourcePath


### A bit of context

Let's see a bit better how it works by using an example:

#### Scenario

We want to install an application. Some required files are provided as needed (they do not need any transformation), and other are provided in a zip file that is nested within other zip package. Moreover, some of these nested files are configuration files that must be customised (modified) for the specific application.

The process should be automated with PowerShell, in such a way that it can be stored and maintained through a Source Control tool such as Git.

The definition of what transformations are required must be set in a text file easy to read with any text processor.

### Assets transformation configuration file

An assets configuration file describes the following:

 - The source files
 - Transformations to be applied
 - The output (resulting files).

Its most basic structure is as follows:

    {
        "assets": [
            {"SourcePath": "File1.xml", "TargetPath": "Output"}
        ]
    }

The configuration above, has a root object with a member named "assets" which is an array of objects. In this case the "assets" array has only one element with a property "SourcePath" and a property "TargetPath that indicates where to find an input file and where to save it respectively. There are no transformations, therefore the source file will be copied as it is.

In other words, the source file, named "File1.xml", will be copied as it is into the folder "Output". The location of the source and the target paths will be provided dynamically, in PowerShell call that triggers the process.

Let's add now a simple transformation:

    {
        "assets": [
            {"SourcePath": "File1.xml", "TargetPath": "Output"},
            {
			    "SourcePath": "ParentFile.zip",
			    "Transforms":[
				    {"Type": "UnzipTransform", "TargetPath": "ParentFile"}
			    ],
			    "assets": [
				    {
					    "SourcePath": "NestedArchive1.zip",
					    "TargetPath": "Output"
				    }
			    ]
		    }
        ]
    }

The configuration above is a bit more interesting. Besides the "File1.xml" file, it takes the file named "ParentFile.zip" from the root source folder, it applies one transformation named "UnzipTransform" and saves the result in a folder named "ParentFile". In other words, it extracts the content of the file "ParentFile.zip" into the folder "ParentFile"

The root location of the target folder in the transformation, in this case the root location for the folder "ParentFile", depends on whether there are more transformations or whether we want only part of its content instead of all. There are two possible locations which are both provided when the transformation process is triggered through PowerShell:

1. **Assets Transform Path**: If more transformations are required over an asset or if we are interested only in part of its conent then the output of a transformation will be considered temporary and will be stored in the "Assets Transform Path".
2. **Target Path**: If the transformation is the last one and sub-assets have been defined then the result of the transformation will be rooted in the "Target Path"

In the example above, the folder "ParentFile" will be considered temporary and created in the folder "Assets Transform Path" because the presence of the property "assets", defined after the property "Transforms", indicates that only part of its content is required.

Let's make the example a bit more interesting:

    {
        "assets": [
            {"SourcePath": "File1.xml", "TargetPath": "Output"},
            {
			    "SourcePath": "ParentFile.zip",
			    "Transforms":[
				    {"Type": "UnzipTransform", "TargetPath": "ParentFile"}
			    ],
			    "assets": [
				    {
					    "SourcePath": "NestedArchive1.zip",
					    "TargetPath": "Output"
				    },
				    {
					    "SourcePath": "NestedArchive2.zip",
					    "Transforms":[
						    {"Type": "UnzipTransform", "TargetPath": "NestedArchive2"}
					    ],
					    "assets": [
						    {
							    "SourcePath": "settings.json",
							    "Transforms":[
								    {
									    "Type": "PowerShellScriptTransform", 
									    "PSScript": "Transforms\\settings.ps1", 
									    "TargetPath": "settings-custom.json"
								    }
							    ],
							    "TargetPath": "Output"
						    }
					    ]
				    }
			    ]
		    }
        ]
    }

In the configuration above a new file named "NestedArchive2.zip", is taken from the folder "ParentFile" and unziped nested in the folder "ParentFile\NestedArchive2".

Inside the new folder "NestedArchive2", there is a file named "settings.json" that will be transformed by a custom PowerShell script named "settings.ps1" and the result will be stored in the "Output" folder with the name "settings-custom.json". The root location of the custom PowerShell script "settings.ps1" is provided by the process that triggers the transformations (parameter "" in cmdlet "Invoke-ProcessAssets").

Let's dive into the custom transformation PowerShell script named "settings.ps1": 

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( {Test-Path $_ -PathType  'Leaf'})] 
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [ValidateScript( {Test-Path $_ -IsValid})] 
        [string]$TargetPath
    )

    $config = Get-Content $SourcePath | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json;

    $config.Parameters | Add-Member -Name 'SitePhysicalPath' -Value @{'Type' = 'string'; 'Description' = 'DockerImageBuild: Build process to specify value.'} -MemberType NoteProperty;
    $config.Parameters | Add-Member -Name 'SiteDataFolder' -Value @{'Type' = 'string'; 'Description' = 'DockerImageBuild: Build process to specify value.'} -MemberType NoteProperty;

    $config.Variables.'Site.PhysicalPath' = "[parameter('SitePhysicalPath')]";
    $config.Variables.'Site.DataFolder' = "[parameter('SiteDataFolder')]";

    $config.Tasks.CreatePaths.Params.Exists += '[variable(''Site.DataFolder'')]';
    $config.Tasks.InstallWDP.Params.Arguments | Add-Member -Name 'Skip' -Value @(@{'ObjectName' = 'dbDacFx'}, @{'ObjectName' = 'dbFullSql'}) -MemberType NoteProperty;

    ConvertTo-Json $config -Depth 50 | Set-Content -Path $TargetPath;

The above PowerShell script, reads a JSON file, modifies it by adding some members and updating some values and saves the result in a folder.

The location of the source file, and the output file are passed as parameters by the Bendev Assets Management module and are taken from the configuration files described earlier.


## Prerequisites

The prerequisites to use the module are as follow:

 - PowerShell Version 5.0
 - Install or import the module (see following section)
 - Local Source folder with the required source files
 - Local folder where temporary files and folders will be saved
 - Local Target folder where the final output will be saved.

## Installing and Importing the Module

As any standard PowerShell module, Bendev Assets Management module needs to be imported to be available. Before that, it needs to be downloaded from [GitHub](https://github.com/Ben-m-s/Bendev.Assets.Management).

Once the module is downloaded it can be imported with the following command:

    Import-Module -Name $PathToTheModulesFolder -Force -Verbose

The above cmdlet requires you to provide where the module is stored in the local machine. This requirement can be skipped by installing the module in a standard location where PowerShell can find it. Which can be achieved by running the PowerShell script named "install.ps1", located in the root folder of the module.

Once the module is installed, it can be imported as follows:

    Import-Module Bendev.Assets.Management -Force -Verbose

### PowerShell Gallery

The module is also available through the [PowerShell Gallery](https://www.powershellgallery.com/packages/Bendev.Assets.Management). This means that you can downloading and install it in one single step, without providing any URL or local path. This is the most convenient way to do it. The required command is as follows:

	Install-Module -Name "Bendev.Assets.Management"

Running the previous cmdlet (Install-Module) without having explicitly trusted the PowerShell Gallery (PSGallery) you get the following message:

    *Untrusted repository
    You are installing the modules from an untrusted repository. If you trust this repository, 
    change its InstallationPolicy value by running the Set-PSRepository cmdlet. Are you sure you 
    want to install the modules from 'PSGallery'?
    [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "N"):*


You still can install the module by clicking "Y".

Alternatively, to avoid the message, you can trust the repository by running:

	Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

The inverse operation, to un-trust the repository, is:

	Set-PSRepository -Name "PSGallery" -InstallationPolicy Untrusted


## Examples provided with the module

The Bendev Assets Management module has a couple of examples of configuration files along with their custom transformation scripts and some tests scripts, although the actual source packages (files to be transformed) are available only if you have a Sitecore license, through the [Sitecore website](https://dev.sitecore.net/Downloads.aspx).

### Example 1

    \Bendev.Assets.Management\Tests\ProcessAssets-Sample1-tests.ps1

#### Configuration file:

    \Bendev.Assets.Management\Tests\ConfigSamples\Assets1.json

#### Transformation Scripts:

    \Bendev.Assets.Management\Tests\Transforms\sitecore-XM1-cm.ps1

### Example 2

    \Bendev.Assets.Management\Tests\ProcessAssets-Sample2-tests.ps1

#### Configuration file:

    \Bendev.Assets.Management\Tests\ConfigSamples\Assets2.json

#### Transformation Scripts:

    \Bendev.Assets.Management\Tests\Transforms\sitecore-xp0.ps1
    \Bendev.Assets.Management\Tests\Transforms\xconnect-xp0.ps1

### Example 3

The following scripts shows alternative ways to instantiate the [Assets] class, other than parsing from a JSON file.

    \Bendev.Assets.Management\Tests\Asset.tests.ps1

## Out of the box Transforms

### Type of transforms
The Bendev Assets Management module has two kind of transformations:

  - Custom script transforms
  - Module transforms

#### Custom script transforms

This is the PowerShell script transform that has been already seen in previous sections. It consists of a simple PowerShell script with a few predefined parameters that can implement any business logic to transform an asset.

To define this kind of transform in the configuration file, a wrapper Module transform named "PowerShellScriptTransform" must be used. See the following sections for more details about "Module transforms" and the "PowerShellScriptTransform" transform.

#### Module transforms

Although we have already seen them, they have not been properly introduced. Module transforms are PowerShell classes that inherit from a base class named [Transform]. The name of the class of this kind of transforms can be specified in the configuration file within the property "Transforms" to indicate the kind of transform to be applied.

#### UnzipTransform

It uses the PowerShell cmdlet [Expand-Archive](https://docs.microsoft.com/en-us/PowerShell/module/microsoft.PowerShell.archive/expand-archive) to decompress zip files.

#### DotNetUnzipTransform

It uses the .NET class [System.IO.Compression.ZipArchiveMode](https://msdn.microsoft.com/es-es/library/system.io.compression.ziparchivemode(v=vs.110).aspx) to decompress zip files. The reason for having two different transforms with the same purpose is because some zip files must be decompressed with a specific method.

#### PowerShellScriptTransform

This Module transform is a wrapper transform in charge of running "Custom script" transforms that must be provided along with the configuration JSON file.

## Extensibility

The OOTB transformations are PowerShell classes that inherit from a base class named [Transform]. It is possible to extend the Bendev Assets Management module by implementing new classes with additional functionality.

The Community is welcome to contribute.

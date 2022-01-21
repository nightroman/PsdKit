<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)
#>

Set-StrictMode -Version Latest
$ModuleName = 'PsdKit'

# Synopsis: Remove temp files.
task clean {
	remove z
}

# Synopsis: Build help by https://github.com/nightroman/Helps
task help @{
	Inputs = 'PsdKit.psm1', 'PsdKit-Help.ps1'
	Outputs = 'PsdKit-Help.xml'
	Jobs = {
		. Helps.ps1
		Import-Module PsdKit
		Convert-Helps $ModuleName-Help.ps1 $ModuleName-Help.xml
	}
}

# Synopsis: Build this module manifest from the template.
task manifest @{
	Inputs = 'PsdKit.psm1', 'Release-Notes.md', 'Examples\Build-Manifest.ps1'
	Outputs = 'PsdKit.psd1'
	Jobs = {Examples\Build-Manifest.ps1}
}

# Synopsis: Tests versions.
task version {
	$version = switch -Regex -File Release-Notes.md {'##\s+v(\d+\.\d+\.\d+)' {$Matches[1]; break}}
	assert $version
	($version2 = (Import-Psd PsdKit.psd1).ModuleVersion)
	equals $version $version2
}

# Synopsis: Copy scripts to the project.
task updateScript {
	$it = 'Update-PsdWebData.ps1'
	foreach($it in $it) {
		$source = Get-Item (Get-Command $it).Definition
		$target = Get-Item "Examples/$it"
		assert ($target.LastWriteTime -le $source.LastWriteTime)
		Copy-Item $source $target
	}
}

# Synopsis: Make the module folder.
task module help, version, updateScript, {
	remove z
	$dir = "$BuildRoot\z\PsdKit"
	$null = mkdir $dir

	Copy-Item -Destination $dir @(
		'about_PsdKit.help.txt'
		'PsdKit.psd1'
		'PsdKit.psm1'
		'LICENSE'
		'PsdKit-Help.xml'
	)
}

task pushPSGallery module, {
	$NuGetApiKey = Read-Host NuGetApiKey
	Publish-Module -NuGetApiKey $NuGetApiKey -Path z/PsdKit
},
clean

# Synopsis: Test PS v3-5
task test5 {
	Invoke-Build ** Tests
}

# Synopsis: Test PS Core.
task test7 {
	exec {pwsh -NoProfile -Command Invoke-Build test5}
}

# Synopsis: Test versions.
task test test5, test7

task . updateScript, manifest, help, test

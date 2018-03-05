
<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)
#>

Set-StrictMode -Version Latest
$ModuleName = 'PsdKit'

# Synopsis: Test v3+ and v2.
task Test Test3, Test2, Test6

# Synopsis: Test PS v3-5
task Test3 {
	Invoke-Build **
}

# Synopsis: Test PS v2.
task Test2 {
	exec {powershell.exe -Version 2 -NoProfile -Command Invoke-Build Test3}
}

# Synopsis: Test PS v6.
task Test6 -If $env:powershell6 {
	exec {& $env:powershell6 -NoProfile -Command Invoke-Build Test3}
}

# Synopsis: Build help by https://github.com/nightroman/Helps
task Help @{
	Outputs = 'PsdKit-Help.xml'
	Inputs = 'PsdKit.psm1', 'PsdKit-Help.ps1'
	Jobs = {
		. Helps.ps1
		Import-Module PsdKit
		Convert-Helps $ModuleName-Help.ps1 $ModuleName-Help.xml
	}
}

# Synopsis: Tests versions.
task Version {
	($version1 = .{ switch -Regex -File Release-Notes.md {'##\s+v(\d+\.\d+\.\d+)' {return $Matches[1]}} })
	assert $version1
	Import-Module PsdKit
	$version2 = (Import-Psd PsdKit.psd1).ModuleVersion
	equals $version1 $version2
}

# Synopsis: Copy scripts to the project.
task UpdateScript {
	$it = 'Update-PsdWebData.ps1'
	foreach($it in $it) {
		$source = Get-Item (Get-Command $it).Definition
		$target = Get-Item "Examples/$it"
		assert ($target.LastWriteTime -le $source.LastWriteTime)
		Copy-Item $source $target
	}
}

# Synopsis: Make the module folder.
task Module Help, Version, UpdateScript, {
	Remove-Item [z] -Force -Recurse
	$dir = "$BuildRoot\z\PsdKit"
	$null = mkdir $dir

	Copy-Item -Destination $dir @(
		'about_PsdKit.help.txt'
		'PsdKit.psd1'
		'PsdKit.psm1'
		'LICENSE.txt'
		'PsdKit-Help.xml'
	)
}

# Synopsis: Remove temp files.
task Clean {
	Get-Item z -ErrorAction 0 |
	Remove-Item -Force -Recurse
}

task . UpdateScript, Help, Test

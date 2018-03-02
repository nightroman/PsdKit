
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

# Synopsis: Make the module folder.
task Module Help, {
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

task . Help, Test

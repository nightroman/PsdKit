
<#
.Synopsis
	Builds the module manifest from the template and dynamic data.

.Description
	This script creates the manifest as the ordered dictionary:
	- ModuleVersion is extracted from the release notes.
	- FunctionsToExport are populated from the module.
	- Other rarely changed data are defined here.
#>

$root = "$PSScriptRoot\.."
$module = Import-Module $root\PsdKit.psm1 -Scope Local -PassThru
$version = switch -Regex -File $root\Release-Notes.md {'##\s+v(\d+\.\d+\.\d+)' {$Matches[1]; break}}

[ordered] @{
	Author = 'Roman Kuzmin'
	ModuleVersion = $version
	Description = 'PowerShell data (psd1) tool kit'
	CompanyName = 'https://github.com/nightroman'
	Copyright = 'Copyright (c) Roman Kuzmin'

	PowerShellVersion = '2.0'
	ModuleToProcess = 'PsdKit.psm1'
	GUID = '207f989e-f0e2-4884-b3be-45fcd1fdd0e7'

	AliasesToExport = @()
	CmdletsToExport = @()
	VariablesToExport = @()
	FunctionsToExport = @($module.ExportedFunctions.Keys)

	PrivateData = @{
		PSData = [ordered] @{
			ProjectUri = 'https://github.com/nightroman/PsdKit'
			LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'
			ReleaseNotes = 'https://github.com/nightroman/PsdKit/blob/master/Release-Notes.md'
			Tags = 'psd1', 'data', 'serialization', 'configuration'
		}
	}
} | ConvertTo-Psd | Set-Content $root\PsdKit.psd1

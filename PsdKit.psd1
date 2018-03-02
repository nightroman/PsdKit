@{
	Author = 'Roman Kuzmin'
	ModuleVersion = '0.0.2'
	Description = 'PowerShell data (psd1) tool kit'
	CompanyName = 'https://github.com/nightroman'
	Copyright = 'Copyright (c) Roman Kuzmin'

	PowerShellVersion = '2.0'
	ModuleToProcess = 'PsdKit.psm1'
	GUID = '207f989e-f0e2-4884-b3be-45fcd1fdd0e7'

	AliasesToExport = @()
	CmdletsToExport = @()
	VariablesToExport = @()
	FunctionsToExport = @(
		'Convert-PsdToXml'
		'ConvertTo-Psd'
		'Convert-XmlToPsd'
		'Export-PsdXml'
		'Get-PsdXml'
		'Import-Psd'
		'Import-PsdXml'
		'Set-PsdXml'
	)

	PrivateData = @{
		PSData = @{
			Tags = 'psd1', 'configuration', 'data'
			ProjectUri = 'https://github.com/nightroman/PsdKit'
			LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'
			ReleaseNotes = 'https://github.com/nightroman/PsdKit/blob/master/Release-Notes.md'
		}
	}
}

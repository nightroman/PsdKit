
<#
.Synopsis
	Updates special psd1 data islands using Invoke-RestMethod.

.Description
	The psd1 file is supposed to have one or more data islands like

		@{
			DataUrl = 'https://api.github.com/repos/nightroman/PsdKit'
			Data = @{ open_issues = 0 }
		}

		- DataUrl
			The URL for Invoke-RestMethod.
		- Data
			The table of properties to be updated from the result.
			If it is empty then the whole result is assigned.
			Then you can remove not interesting items.

	Data islands may be located anywhere in psd1 and may have extra items in
	addition to the required DataUrl and Data.

	The command writes text messages like "url property value1 -> value2" for
	changed items. If nothing is changed then the psd1 file is not updated.

.Parameter Path
	Specifies the psd1 file for input and output.
	Default: "web.psd1" in the current location.
#>

param(
	[Parameter()]
	[string] $Path = 'web.psd1'
)
Set-StrictMode -Off
$ErrorActionPreference = 1
trap {$PSCmdlet.ThrowTerminatingError($_)}
[System.Net.ServicePointManager]::SecurityProtocol = "$([System.Net.ServicePointManager]::SecurityProtocol),Tls11,Tls12"

Import-Module PsdKit
$xml = Import-PsdXml $Path
$change = 0

# for all web data nodes, i.e. tables with items "DataUrl"
foreach($DataUrlNode in $xml.SelectNodes('//Item[@Key="DataUrl"]')) {
	$url = Get-Psd $DataUrlNode
	$res = Invoke-RestMethod $url
	$DataItemNode = @($DataUrlNode.SelectNodes('../Item[@Key="Data"]/Table/Item'))
	if ($DataItemNode) {
		# update each changed item
		foreach($DataItemNode in $DataItemNode) {
			$value1 = Get-Psd $DataItemNode
			$key = $DataItemNode.Key
			$value2 = $res.$key
			if (![string]::Equals((ConvertTo-Psd $value1), (ConvertTo-Psd $value2))) {
				++$change
				"$url $key $value1 -> $value2"
				Set-Psd $DataItemNode $value2
			}
		}
	}
	else {
		# set the whole object
		++$change
		"$url updated"
		Set-Psd $DataUrlNode $res '../Item[@Key="Data"]'
	}
}

# save if changed
if ($change) {
	Export-PsdXml $Path $xml
}

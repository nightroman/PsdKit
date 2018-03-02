
<#
.Synopsis
	Common stuff for tests.

.Parameter CommandName
		Optionally specifies the command in order to add generic tasks.
#>

[CmdletBinding()] param(
	$CommandName
)

Import-Module ../PsdKit.psm1
$Version = $PSVersionTable.PSVersion.Major

# Common command tasks
if ($CommandName) {
	task Help {
		Get-Help $CommandName -Full | Out-String
	}
}

# Asserts the new hash is the same as expected.
function Test-Hash([string]$New, [string]$Expected) {
	$New = ([guid][System.Security.Cryptography.MD5]::Create().ComputeHash([byte[]][char[]]$New)).ToString('N')
	if ($New -ne $Expected) {Write-Error "Unexpected new hash: $New" -ErrorAction 1}
}

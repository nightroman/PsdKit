
. ./About.ps1

task Main {
	$xml = Import-PsdXml test-01.psd1
	Export-PsdXml z.psd1 $xml

	Assert-SameFile test-01.psd1 z.psd1
	Remove-Item z.psd1
}

task BadXml {
	#! on problems, the target file should not be touched
	Remove-Item [z].psd1
	$xml = [xml]'<bar><bad/></bar>'
	($r = try {Export-PsdXml z.psd1 $xml} catch {$_})
	equals "$r" "Unexpected XML element 'bad'."
	assert (!(Test-Path z.psd1))

	($r = try {Convert-XmlToPsd $xml} catch {$_})
	equals "$r" "Unexpected XML element 'bad'."
}

task ExtractPart {
	$xml = {
		@{
			data1 = @{p1=1; p2=2}
			data2 = @{p1=2; p2=3}
		}
	} | Convert-PsdToXml
	$node = $xml.SelectSingleNode('/Data/Table/Item[@Key="data2"]/Table')
	($r = Convert-XmlToPsd $node)
	equals $r '@{ p1 = 2; p2 = 3 }'
}

task CheckRestrictedLanguage -If ($Version -ge 3) {
	$text = @'
@{
	var1 = $BuildRoot
	env1 = $env:USERNAME
}
'@

	$script = [scriptblock]::Create($text)
	$script.CheckRestrictedLanguage([string[]]@(), ([string[]]'*'), $true)
	($r = & $script)

	equals $r.var1 $BuildRoot
	equals $r.env1 $env:USERNAME
}

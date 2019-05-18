
. ./About.ps1 Import-PsdXml

task string-single-quoted-simple {
	#! was converted to a bad here-string
	$s1 = @'
'line1
''@ line2
line3'
'@
	[IO.File]::WriteAllText("$BuildRoot/z.psd1", $s1)

	$xml = Import-PsdXml z.psd1
	$r = $xml.SelectSingleNode('Data/String')
	equals $r.Attributes.Count 0

	($r = Convert-XmlToPsd $xml)
	equals $r $s1

	Remove-Item z.psd1
}

# Import data with script blocks and convert back to psd1.
task Blocks {
	$xml = Import-PsdXml test-03.psd1
	$xml.InnerXml

	$r = Convert-XmlToPsd $xml
	equals $r ([System.IO.File]::ReadAllText("$BuildRoot\test-03.psd1"))
}

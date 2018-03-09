
. ./About.ps1 Export-PsdXml

#! on problems, the target file should not be touched
task BadXml {
	Remove-Item [z].psd1
	$xml = [xml]'<bar><bad/></bar>'
	($r = try {Export-PsdXml z.psd1 $xml} catch {$_})
	equals "$r" "Unexpected XML element 'bad'."
	assert (!(Test-Path z.psd1))
}

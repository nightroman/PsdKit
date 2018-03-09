
. ./About.ps1 Convert-XmlToPsd

task BadXml {
	$xml = [xml]'<bar><bad/></bar>'
	($r = try {Convert-XmlToPsd $xml} catch {$_})
	equals "$r" "Unexpected XML element 'bad'."
}

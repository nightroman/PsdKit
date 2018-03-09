
. ./About.ps1 Convert-PsdToXml

#! ConvertFrom-Json ~ same
task ScriptBlockArgumentNoInput {
	($r = try {Convert-PsdToXml {1 + 2}} catch {$_})
	equals $r.FullyQualifiedErrorId 'ScriptBlockArgumentNoInput,Convert-PsdToXml'
}

task BadOperator {
	($r = try {{1 + 2} | Convert-PsdToXml} catch {$_})
	equals "$r" "Unexpected token Operator '+' at 1:3"
}

task BadSyntax {
	($r = try {Convert-PsdToXml '@{'} catch {$_})
	if ($Version -ge 6) {
		equals "$r" "Parser error at 1:3 : Missing closing '}' in statement block or type definition."
	}
	else {
		equals "$r" 'Parser error at 1:3 : The hash literal was incomplete.'
	}
}

task SimpleTest {
	$xml = Convert-PsdToXml @'
42
3.14
'@
	equals $xml.InnerXml '<Data><Number>42</Number><NewLine /><Number>3.14</Number></Data>'
}

# single-quoted-simple is preserved
task single-quoted-simple {
	#! was converted to a bad here-string
	$s1 = {'line1
''@ line2
line3'}.ToString()

	$xml = Convert-PsdToXml $s1
	$r = $xml.SelectSingleNode('Data/String')
	equals $r.Attributes.Count 0

	($r = Convert-XmlToPsd $xml)
	equals $r $s1
}

# single-quoted-verbatim is preserved
task single-quoted-verbatim {
	$s1 = {@'
line1
line2
'@}.ToString()

	$xml = Convert-PsdToXml $s1
	$r = $xml.SelectSingleNode('Data/String')
	equals $r.GetAttribute('Type') '1'

	($r = Convert-XmlToPsd $xml)
	equals $r $s1
}

# double-quoted-simple is saved as single-quoted-simple
task double-quoted-simple {
	#! was converted to a bad here-string
	$s1 = {"line1
'@ line2
line3"}.ToString()

	$xml = Convert-PsdToXml $s1
	$r = $xml.SelectSingleNode('Data/String')
	equals $r.Attributes.Count 0

	($r = Convert-XmlToPsd $xml)
	equals $r @'
'line1
''@ line2
line3'
'@
}

# double-quoted-verbatim is saved as single-quoted-simple
# - saving as @""@ is possible but more difficult due to escaping
# - saving as @''@ may produce invalid data, no way to escape `'@`
task double-quoted-verbatim {
	$s1 = {@"
@'
line1
line2
'@
"@}.ToString()

	$xml = Convert-PsdToXml $s1
	$r = $xml.SelectSingleNode('Data/String')
	equals $r.Attributes.Count 0

	($r = Convert-XmlToPsd $xml)
	equals $r @"
'@''
line1
line2
''@'
"@
}

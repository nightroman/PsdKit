
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

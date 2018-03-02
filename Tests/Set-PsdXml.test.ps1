
. ./About.ps1 Set-PsdXml

task SetValueManual {
	$xml = {
		@{
			#comment
			name = 'some name'
			version = '1.1.1'
		}
	} | Convert-PsdToXml

	$r = $xml.SelectSingleNode('Data/Table/Item[@Key="version"]/String')
	equals $r.InnerText '1.1.1'

	$r.InnerText = '2.2.2'
	($r = Convert-XmlToPsd $xml)
	Test-Hash $r f8911b40586ca40bd9f0af5eba2964ef
}

task SetValueXPath {
	$xml = {
		@{
			#comment
			name = 'some name'
			version = '1.1.1'
			answer = 42
		}
	} | Convert-PsdToXml

	Set-PsdXml $xml '#changed' 'Data/Table/Comment'
	Set-PsdXml $xml 'another name' 'Data/Table/Item[@Key="name"]'
	Set-PsdXml $xml 2.2.2 'Data/Table/Item[@Key="version"]'
	($r = Convert-XmlToPsd $xml)
	Test-Hash $r e648dcba706c19d93766355722bf48c8
}

task SetValueNode {
	$xml = {
		@{
			#comment
			name = 'some'
			answer = 42
		}
	} | Convert-PsdToXml

	Set-PsdXml $xml.SelectSingleNode('Data/Table/Comment') '#changed'
	Set-PsdXml $xml.SelectSingleNode('Data/Table/Item[@Key="name"]') another
	Set-PsdXml $xml.SelectSingleNode('Data/Table/Item[@Key="answer"]') 'text'

	($r = Convert-XmlToPsd $xml)
	Test-Hash $r 2823a2ef520d53b705d006da5cd183a4
}

task SetNotItem {
	#! used to get Indent="2", fixed
	$xml = Convert-PsdToXml '@{x = 42}'

	# old type
	Set-PsdXml $xml.SelectSingleNode('Data/Table/Item[@Key="x"]/Number') 99
	($r = $xml.InnerXml)
	equals $r '<Data><Table><Item Key="x"><Number>99</Number></Item></Table></Data>'

	# new type
	Set-PsdXml $xml.SelectSingleNode('Data/Table/Item[@Key="x"]/Number') text
	($r = $xml.InnerXml)
	equals $r '<Data><Table><Item Key="x"><String>text</String></Item></Table></Data>'
}

task SetCommentGood {
	$xml = {
		@{
			#comment1
			x = 42
		}
	} | Convert-PsdToXml

	$node = $xml.SelectSingleNode('//Comment')
	equals (Get-PsdXml $node) '#comment1'

	Set-PsdXml $node '#comment2'
	equals (Get-PsdXml $node) '#comment2'

	Set-PsdXml $node '<#comment3#>'
	equals (Get-PsdXml $node) '<#comment3#>'

	($r = Convert-XmlToPsd $xml)
	Test-Hash $r d380fc73d0cd10c19680276809567425
}

task SetCommentBad {
	$xml = {
		@{
			#comment1
			x = 42
		}
	} | Convert-PsdToXml

	$node = $xml.SelectSingleNode('//Comment')
	equals (Get-PsdXml $node) '#comment1'

	($r = try {Set-PsdXml $node 42} catch {$_})
	equals "$r" 'Comment must be a string.'
	equals $r.FullyQualifiedErrorId Set-PsdXml

	($r = try {Set-PsdXml $node "#bar`n"} catch {$_})
	equals "$r" 'Line comment must be one line.'
	equals $r.FullyQualifiedErrorId Set-PsdXml

	($r = try {Set-PsdXml $node '<#bar'} catch {$_})
	equals "$r" "Block comment must end with '#>'."
	equals $r.FullyQualifiedErrorId Set-PsdXml

	($r = try {Set-PsdXml $node 'bar'} catch {$_})
	equals "$r" 'Comment must be line #... or block <#...#>.'
	equals $r.FullyQualifiedErrorId Set-PsdXml
}

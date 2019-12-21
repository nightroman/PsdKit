
. ./About.ps1 Get-Psd
$Version = $PSVersionTable.PSVersion.Major

task BadNumber {
	$xml = [xml]'<Number>bad</Number>'
	($r = try {Get-Psd $xml} catch {$_})
	equals "$r" "Not supported number 'bad'."
}

task BadVariable {
	$xml = [xml]'<Variable>bad</Variable>'
	($r = try {Get-Psd $xml} catch {$_})
	equals "$r" "Not supported variable 'bad'."
}

task BadCastType {
	$xml = [xml]'<Cast Type="Version">bad</Cast>'
	($r = try {Get-Psd $xml} catch {$_})
	equals "$r" "Cast to not supported type 'Version'."
}

task BadCastValue {
	$xml = [xml]'<Cast Type="int">bad</Cast>'
	($r = try {Get-Psd $xml} catch {$_})
	assert ("$r" -like 'Cannot convert value "bad" to type "System.Int32".*')
}

task Test {
	$xml = {
		@{
			#comment
			version = '1.1.1'
		}
	} | Convert-PsdToXml

	($r = Get-Psd $xml 'Data/Table/Comment')
	equals $r '#comment'

	($r = Get-Psd $xml 'Data/Table/Item[@Key="version"]')
	equals $r '1.1.1'
}

task Cases {
	$script = {
		@{
			string = 'name'
			int = 1
			long = 9223372036854775807
			double = 1.84467440737096E+19
			decimal = 79228162514264337593543950335
			date = [datetime] '2000-11-22'
			array = @(
				1
				'name'
				[datetime] '2000-11-22'
				@{
					x = 1
				}
			)
			table = @{
				x = 1
			}
		}
	}
	$data = & $script
	$xml = $script | Convert-PsdToXml

	$r = Get-Psd $xml.Data.Table
	assert ($r -is [System.Collections.Specialized.OrderedDictionary])
	assert ($r.table -is [System.Collections.Specialized.OrderedDictionary])
	assert ($r.int -is [int])
	assert ($r.long -is [long])
	assert ($r.double -is [double])
	assert ($r.decimal -is [double]) #??
	assert ($r.date -is [datetime])
	if ($Version -ge 3) {
		assert ($r.array -is [System.Collections.Generic.List[object]])
	}
	else {
		assert ($r.array -is [object[]]) #??
	}

	# v6- decimal = 7.92281625142643E+28
	# v7+ decimal = 7.922816251426434E+28
	($r = ConvertTo-Psd $r)
	if ($Version -ge 7) {
		Test-Hash $r cea45d84b440f089c375e5fc56ff902e
	}
	else {
		Test-Hash $r c2354d7d6b6b9d57c6de6cc29b3bee92
	}

	assert ($data.decimal -is [decimal])
}

task ArrayCommentCommaSemicolon {
	$xml = {
		@(
			#comment
			1, 2
			#comment
			3; 4;
		)
	}.ToString() | Convert-PsdToXml

	$r = Get-Psd $xml.DocumentElement.Array
	($r = ConvertTo-Psd $r)
	Test-Hash $r 0d96781810cd682cf5affdda50f1ca8e
}

task ItemNewLineCommentComma {
	$xml = {
		@{
			x =
				#comment
				1, 2;
		}
	}.ToString() | Convert-PsdToXml

	$r = Get-Psd $xml.DocumentElement.Table.Item
	($r = ConvertTo-Psd $r)
	Test-Hash $r c28b1116f958407000865d39e5866a04
}

task TableNewLineCommentSemicolon {
	$xml = {
		@{
			#comment
			x =
				#! fixed NewLine Comment
				1;
			#comment
			y = 2;
		}
	}.ToString() | Convert-PsdToXml

	$r = Get-Psd $xml.DocumentElement.Table
	($r = ConvertTo-Psd $r)
	Test-Hash $r 55e1d3cf8b7ecb91cb9271dc50bb1928
}

task ItemListVsArray {
	$xml = {
		@{
			x = @(1, 2)
			y = 1, 2
		}
	}.ToString() | Convert-PsdToXml

	$r = Get-Psd $xml.DocumentElement.Table
	if ($Version -ge 3) {
		equals $r.x.GetType() ([System.Collections.Generic.List[object]])
	}
	else {
		equals $r.x.GetType() ([object[]])
	}
	equals $r.y.GetType() ([object[]])
}

task DocumentAndDataNode {
	$xml = Convert-PsdToXml 42
	($r = Get-Psd $xml)
	equals $r 42
	($r = Get-Psd $xml.DocumentElement)
	equals $r 42
	($r = Get-Psd $xml.Data)
	equals $r 42
}

task HexNumber {
    $xml = {@{
    	int = 0xffffffff
    	long = 0xffffffffffffffff
    }}.ToString() | Convert-PsdToXml
    ($r = Get-Psd $xml)
	equals $r.int (-1)
	equals $r.long (-1L)
}

task BlockInData {
	$xml = Convert-PsdToXml '{42}'
	equals $xml.InnerXml '<Data><Block>42</Block></Data>'

	($r = Get-Psd $xml)
	equals ($r.GetType()) ([scriptblock])
	equals (& $r) 42
}

task BlockInTable {
	$xml = Convert-PsdToXml '@{Id=1; Block={42}}'
	equals $xml.InnerXml '<Data><Table><Item Key="Id"><Number>1</Number></Item><Semicolon /><Item Key="Block"><Block>42</Block></Item></Table></Data>'

	($r = Get-Psd $xml '/Data/Table/Item[@Key="Block"]')
	equals ($r.GetType()) ([scriptblock])
	equals (& $r) 42
}

task BlockInArray {
	#! use @(), not just comma separated values
	$xml = Convert-PsdToXml '@{Array=@(1, {42})}'
	equals $xml.InnerXml '<Data><Table><Item Key="Array"><Array><Number>1</Number><Comma /><Block>42</Block></Array></Item></Table></Data>'

	($r = Get-Psd $xml '/Data/Table/Item[@Key="Array"]')
	equals $r.Count 2
	equals $r[0] 1
	equals ($r[1].GetType()) ([scriptblock])
}

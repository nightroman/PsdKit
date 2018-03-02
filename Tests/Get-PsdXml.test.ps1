
. ./About.ps1 Get-PsdXml

task Test {
	$xml = {
		@{
			#comment
			version = '1.1.1'
		}
	} | Convert-PsdToXml

	($r = Get-PsdXml $xml 'Data/Table/Comment')
	equals $r '#comment'

	($r = Get-PsdXml $xml 'Data/Table/Item[@Key="version"]')
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

	$r = Get-PsdXml $xml.Data.Table
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

	($r = ConvertTo-Psd $r)
	Test-Hash $r c2354d7d6b6b9d57c6de6cc29b3bee92

	assert ($data.decimal -is [decimal])
}

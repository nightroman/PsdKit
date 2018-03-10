
Set-StrictMode -Version Latest

$IndentSpecial = @'
	Special values:
		1 ~ tab
		2 ~ two spaces
		4 ~ four spaces
		0 ~ no indentation
		empty ~ four spaces
'@

$IndentPsdXml = @"
	Specifies the indentation string. By default it is four spaces unless it is
	inferred from the original psd1 imported by Import-PsdXml and stored as the
	attribute Indent of the root element Data.

$IndentSpecial
"@

$PsdXmlOutputs = @(
	@{
		type = '[System.Xml.XmlDocument]'
		description = 'PSD-XML document representing psd1 content.'
	}
)

$GetSetXml = @'
	Specifies the input PSD-XML node. It is used as the target or the current
	node for the optional XPath expression.
'@

$GetSetXPath = @'
	Optionally specifies the XPath from the input node to the existing target
	node. If it is omitted or empty then the input node itself is used as the
	target.

	Examples for a module manifest psd1:

		Version and release notes nodes can be specified as:
			//Item[@Key="ModuleVersion"]
			//Item[@Key="ReleaseNotes"]

		Their exact full paths:
			/Data/Table/Item[@Key="ModuleVersion"]
			/Data/Table/Item[@Key="PrivateData"]/Table/Item[@Key="PSData"]/Table/Item[@Key="ReleaseNotes"]
'@

### Convert-PsdToXml command help
@{
	command = 'Convert-PsdToXml'
	synopsis = 'Converts a psd1 string to PSD-XML.'
	description = @'
	For more details about PSD-XML scenarios see

		Import-Module PsdKit
		help about_PsdKit
'@
	parameters = @{
		InputObject = 'Specifies the input psd1-formatted string.'
	}
	outputs = $PsdXmlOutputs
	links = @(
		@{ text = 'Convert-XmlToPsd' }
		@{ text = 'Export-PsdXml' }
		@{ text = 'Import-PsdXml' }
		@{ text = 'Get-PsdXml' }
		@{ text = 'Set-PsdXml' }
	)
}

### Convert-XmlToPsd command help
@{
	command = 'Convert-XmlToPsd'
	synopsis = 'Converts PSD-XML to a psd1 string.'
	description = @'
	For more details about PSD-XML scenarios see

		Import-Module PsdKit
		help about_PsdKit

	Note that the result string includes the trailing new line, if any. Thus,
	if you use it with Set-Content then consider to use its -NoNewLine.
	Otherwise, the file will have more than one empty lines in the end.
'@
	parameters = @{
		Xml = 'The input PSD-XML to be converted.'
		Indent = $IndentPsdXml
	}
	outputs = @(
		@{
			type = '[string]'
			description = 'psd1-formatted string.'
		}
	)
	links = @(
		@{ text = 'Convert-PsdToXml' }
		@{ text = 'Export-PsdXml' }
		@{ text = 'Import-PsdXml' }
		@{ text = 'Get-PsdXml' }
		@{ text = 'Set-PsdXml' }
	)
}

### ConvertTo-Psd command help
@{
	command = 'ConvertTo-Psd'
	synopsis = 'Converts objects to a psd1-formatted strings.'
	description = @'
	This command converts objects to strings in PowerShell data (psd1) format.

	Supported objects in normal mode (use Depth for all objects):
		- [System.Collections.IDictionary] -> @{}
		- [System.Collections.IEnumerable] -> @()
		- [PSCustomObject] -> @{}

	Supported values:
		- [string], [guid], [version], [char], [uri], enum -> single quoted
		- [DateTime] -> [DateTime] x.ToString('o')
		- [bool] -> $true and $false
		- number -> x.ToString()
		- null -> $null

	Note that the result string does not include the trailing new line. Thus,
	if you use ConvertTo-Psd with some Set-Content (save) or Add-Content (log)
	then you do not have to use -NoNewLine, it is added by these commands. But
	on saving by other methods you may need to add a new line.
'@
	parameters = @{
		InputObject = @'
		The input object to be converted or objects from the pipeline.
'@
		Depth = @'
		Tells to convert all objects and specifies the maximum depth. Truncated
		objects are written as ''''. The default value is 0 for supported types
		with the depth limited by the PowerShell call stack.
'@
		Indent = @"
	Specifies the indent string. By default it is four spaces.

$IndentSpecial
"@
	}
	inputs = @(
		@{
			type = '[object]'
			description = 'Objects to be converted to psd1-formatted strings.'
		}
	)
	outputs = @(
		@{
			type = '[string]'
			description = 'psd1-formatted strings.'
		}
	)
	examples = @(
		@{
			code = {
    # Append log records several times
    @{time = Get-Date; text = ...} | ConvertTo-Psd | Add-Content log.psd1

    # Read log records
    Import-Psd log.psd1
			}
		}
		@{
			code = {
    # Browse through $Host data
    $Host | ConvertTo-Psd -Depth 3
			}
		}
	)
	links = @(
		@{ text = 'Import-Psd' }
	)
}

### Export-PsdXml command help
@{
	command = 'Export-PsdXml'
	synopsis = 'Exports PSD-XML to a psd1 file.'
	description = @'
	For more details about PSD-XML scenarios see

		Import-Module PsdKit
		help about_PsdKit
'@
	parameters = @{
		Xml = 'The input PSD-XML to be exported.'
		Path = 'Specifies the output file path.'
		Indent = $IndentPsdXml
	}
	links = @(
		@{ text = 'Convert-PsdToXml' }
		@{ text = 'Convert-XmlToPsd' }
		@{ text = 'Import-PsdXml' }
		@{ text = 'Get-PsdXml' }
		@{ text = 'Set-PsdXml' }
	)
}

### Get-PsdXml command help
@{
	command = 'Get-PsdXml'
	synopsis = 'Gets node PowerShell data.'
	description = @'
	This command parses and returns the specified node value. It does not
	invoke any psd1 code, this is safe like importing psd1 in a usual way.

	Returned values depend on node types:

		String
			[string]
		Number
			[int], [long], [double]
		Variable
			$false, $true, $null
		Array
			[System.Collections.Generic.List[object]]
		Table
			[System.Collections.Specialized.OrderedDictionary]
		Cast
			Values converted to primitive types, e.g. [DateType]
		Item
			One of the above values.
		Comment
			[string]

	Node children must not include comments, commas, and semicolons. In other
	words, Get-PsdXml guarantees that comments and separators are not lost on
	using Set-PsdXml.

	Nodes with included comments, commas, and semicolons should be treated as
	usual XML with special PSD structure. This is fiddly and error prone but
	doable. Yet it is easier to keep some parts of psd1 simple for Get-PsdXml.

	For more details about PSD-XML scenarios see

		Import-Module PsdKit
		help about_PsdKit
'@
	parameters = @{
		Xml = $GetSetXml
		XPath = $GetSetXPath
	}
	links = @(
		@{ text = 'Convert-PsdToXml' }
		@{ text = 'Convert-XmlToPsd' }
		@{ text = 'Export-PsdXml' }
		@{ text = 'Import-PsdXml' }
		@{ text = 'Set-PsdXml' }
	)
}

### Import-Psd command help
@{
	command = 'Import-Psd'
	synopsis = 'Imports objects from a psd1 file.'
	description = @'
	This command is similar to:
	- Import-LocalizedData but slightly easier to use
	- Import-PowerShellDataFile but not just a hashtable
'@
	parameters = @{
		Path = 'The input file path.'
	}
	outputs = @(
		@{
			type = '[object]', '[hashtable]'
			description = @'
	Imported object(s), often a single hashtable. But psd1 files may contain
	several objects and not necessarily hashtables.
'@
		}
	)
	links = @(
		@{ text = 'ConvertTo-Psd' }
	)
}

### Import-PsdXml command help
@{
	command = 'Import-PsdXml'
	synopsis = 'Imports psd1 file as PSD-XML.'
	description = @'
	For more details about PSD-XML scenarios see

		Import-Module PsdKit
		help about_PsdKit
'@
	parameters = @{
		Path = 'Specifies the input psd1 file path.'
	}
	outputs = $PsdXmlOutputs
	links = @(
		@{ text = 'Convert-PsdToXml' }
		@{ text = 'Convert-XmlToPsd' }
		@{ text = 'Export-PsdXml' }
		@{ text = 'Get-PsdXml' }
		@{ text = 'Set-PsdXml' }
	)
}

### Set-PsdXml command help
@{
	command = 'Set-PsdXml'
	synopsis = 'Sets node PowerShell data.'
	description = @'
	This command converts data to XML using ConvertTo-Psd and Convert-PsdToXml.
	The result XML or context replaces the specified node or its content. Note
	that child comments, commas, and semicolons of the node are not preserved.

	For more details about PSD-XML scenarios see

		Import-Module PsdKit
		help about_PsdKit
'@
	parameters = @{
		Xml = $GetSetXml
		XPath = $GetSetXPath
		Value = 'Specifies the new node value.'
	}
	links = @(
		@{ text = 'Convert-PsdToXml' }
		@{ text = 'Convert-XmlToPsd' }
		@{ text = 'Export-PsdXml' }
		@{ text = 'Import-PsdXml' }
		@{ text = 'Get-PsdXml' }
	)
}


$ErrorActionPreference = 1

#.ExternalHelp PsdKit-Help.xml
function Convert-PsdToXml {
	[OutputType([xml])]
	param(
		[Parameter(Position=0, Mandatory=1, ValueFromPipeline=1)]
		[string] $InputObject
	)
	process {
		trap {ThrowTerminatingError $_}
		New-PsdXml $InputObject
	}
}

#.ExternalHelp PsdKit-Help.xml
function Convert-XmlToPsd {
	[OutputType([string])]
	param(
		[Parameter(Position=0, Mandatory=1)]
		[System.Xml.XmlNode] $Xml,
		[string] $Indent
	)
	trap {ThrowTerminatingError $_}

	if (!$Indent) {
		if (!($doc = $Xml.OwnerDocument)) {$doc = $Xml}
		if ($attr = $doc.DocumentElement.GetAttribute('Indent')) {$Indent = $attr}
	}

	$script:LineStarted = $false
	$script:Indent = Convert-Indent $Indent
	$script:Writer = New-Object System.IO.StringWriter
	try {
		if ($Xml.NodeType -ceq 'Document') {
			Write-XmlChild $Xml.DocumentElement
		}
		elseif ($Xml.Name -ceq 'Item') {
			Write-XmlChild $Xml
		}
		else {
			Write-XmlElement $Xml
		}
		$script:Writer.ToString()
	}
	finally {
		$script:Writer = $null
	}
}

#.ExternalHelp PsdKit-Help.xml
function ConvertTo-Psd {
	[OutputType([String])]
	param(
		[Parameter(Position=0, ValueFromPipeline=1)]
		$InputObject,
		[int] $Depth,
		[string] $Indent
	)
	begin {
		$objects = [System.Collections.Generic.List[object]]@()
	}
	process {
		$objects.Add($InputObject)
	}
	end {
		trap {ThrowTerminatingError $_}

		$script:Depth = $Depth
		$script:Pruned = 0
		$script:Indent = Convert-Indent $Indent
		$script:Writer = New-Object System.IO.StringWriter
		try {
			foreach($object in $objects) {
				Write-Psd $object
			}
			$script:Writer.ToString().TrimEnd()
			if ($script:Pruned) {Write-Warning "ConvertTo-Psd truncated $script:Pruned objects."}
		}
		finally {
			$script:Writer = $null
		}
	}
}

#.ExternalHelp PsdKit-Help.xml
function Export-PsdXml {
	param(
		[Parameter(Position=0, Mandatory=1)]
		[string] $Path,
		[Parameter(Position=1, Mandatory=1)]
		[System.Xml.XmlNode] $Xml,
		[string] $Indent
	)
	trap {ThrowTerminatingError $_}
	$Path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
	[System.IO.File]::WriteAllText($Path, (Convert-XmlToPsd $Xml -Indent $Indent), ([System.Text.Encoding]::UTF8))
}

#.ExternalHelp PsdKit-Help.xml
function Get-Psd {
	param(
		[Parameter(Position=0, Mandatory=1)]
		[System.Xml.XmlNode] $Xml,
		[Parameter(Position=1)]
		[string] $XPath
	)
	trap {ThrowTerminatingError $_}
	if ($XPath) {
		$node = $xml.SelectSingleNode($XPath)
		if (!$node) {throw "XPath selects nothing: '$XPath'."}
	}
	else {
		$node = $Xml
	}
	switch($node.Name) {
		Item {
			return New-ItemPsd $node
		}
		String {
			return $node.InnerText
		}
		Number {
			return New-NumberPsd $node.InnerText
		}
		Variable {
			return New-VariablePsd $node.InnerText
		}
		Comment {
			return $node.InnerText
		}
		Array {
			return New-ArrayPsd $node
		}
		Table {
			return New-TablePsd $node
		}
		Cast {
			return New-CastPsd $node
		}
		Data {
			return New-ItemPsd $node
		}
		'#document' {
			return New-ItemPsd $node
		}
		default {
			throw "Not supported node '$_'."
		}
	}
}

#.ExternalHelp PsdKit-Help.xml
function Import-Psd {
	[OutputType([Hashtable])]
	param(
		[Parameter(Position=0, Mandatory=1)]
		[string] $Path
	)
	trap {ThrowTerminatingError $_}
	$Path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
	Import-LocalizedData -BaseDirectory ([System.IO.Path]::GetDirectoryName($Path)) -FileName ([System.IO.Path]::GetFileName($Path)) -BindingVariable r
	$r
}

#.ExternalHelp PsdKit-Help.xml
function Import-PsdXml {
	[OutputType([xml])]
	param(
		[Parameter(Mandatory=1)]
		[string] $Path
	)
	trap {ThrowTerminatingError $_}
	$script = [System.IO.File]::ReadAllText($PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path))
	New-PsdXml $script
}

#.ExternalHelp PsdKit-Help.xml
function Set-Psd {
	param(
		[Parameter(Position=0, Mandatory=1)]
		[System.Xml.XmlNode] $Xml,
		[Parameter(Position=1, Mandatory=1)]
		[AllowEmptyString()]
		[AllowNull()]
		$Value,
		[Parameter(Position=2)]
		[string] $XPath
	)
	trap {ThrowTerminatingError $_}
	if ($XPath) {
		$node = $xml.SelectSingleNode($XPath)
		if (!$node) {throw 'XPath selects nothing.'}
	}
	else {
		$node = $Xml
	}
	if ($node.NodeType -ne 'Element') {throw "Unexpected node type '$($node.NodeType)'."}

	if ($node.Name -eq 'Comment') {
		if ($Value -isnot [string]) {throw 'Comment must be a string.'}
		if ($Value.StartsWith('#')) {
			if ($Value -match '[\r\n]') {throw 'Line comment must be one line.'}
		}
		elseif ($Value.StartsWith('<#')) {
			if (!$Value.EndsWith('#>')) {throw "Block comment must end with '#>'."}
		}
		else {
			throw 'Comment must be line #... or block <#...#>.'
		}
		$node.InnerText = $Value
		return
	}

	$newXml = Convert-PsdToXml (ConvertTo-Psd $Value)

	$newNode = $newXml.DocumentElement
	if ($newNode.ChildNodes.Count -ne 1) {throw 'Not supported new value.'}
	$newNode = $node.OwnerDocument.ImportNode($newNode.FirstChild, $true)

	if ($node.Name -eq 'Item') {
		if ($node.ChildNodes.Count -ne 1) {throw 'Not supported old value.'}
		$null = $node.ReplaceChild($newNode, $node.FirstChild)
	}
	else {
		$null = $node.ParentNode.ReplaceChild($newNode, $node)
	}
}

function Add-XmlElement {
	[OutputType([System.Xml.XmlElement])]
	param(
		[Parameter(Mandatory=1)]
		[System.Xml.XmlElement] $Xml,
		[Parameter(Mandatory=1)]
		[string] $Name
	)
	$Xml.AppendChild($Xml.OwnerDocument.CreateElement($Name))
}

function Convert-Indent($Indent) {
	switch($Indent) {
		'' {return '    '}
		'1' {return "`t"}
		'2' {return '  '}
		'4' {return '    '}
		'0' {return ''}
	}
	$Indent
}

function ThrowTerminatingError($M) {
	$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]"$M"), $null, 0, $null))
}

function ThrowUnexpectedToken($t1) {
	throw 'Unexpected token {0} ''{1}'' at {2}:{3}' -f $t1.Type, $t1.Content, $t1.StartLine, $t1.StartColumn
}

function Write-Psd($Object, $Depth=0, [switch]$NoIndent) {
	$indent1 = $script:Indent * $Depth
	if (!$NoIndent) {
		$script:Writer.Write($indent1)
	}

	if ($null -eq $Object) {
		$script:Writer.WriteLine('$null')
		return
	}

	$type = $Object.GetType()
	switch([System.Type]::GetTypeCode($type)) {
		Object {
			if ($type -eq [System.Guid] -or $type -eq [System.Version]) {
				$script:Writer.WriteLine("'{0}'", $Object)
				return
			}
			elseif ($type -eq [System.Management.Automation.SwitchParameter]) {
				$script:Writer.WriteLine($(if ($Object) {'$true'} else {'$false'}))
				return
			}
			elseif ($type -eq [System.Uri]) {
				$script:Writer.WriteLine("'{0}'", $Object.ToString().Replace("'", "''"))
				return
			}
			elseif ($script:Depth -and $Depth -ge $script:Depth) {
				$script:Writer.WriteLine("''''")
				++$script:Pruned
				return
			}
			elseif ($Object -is [System.Collections.IDictionary]) {
				if ($Object.Count) {
					$script:Writer.WriteLine('@{')
					$indent2 = $script:Indent * ($Depth + 1)
					foreach($e in $Object.GetEnumerator()) {
						$key = $e.Key
						$keyType = $key.GetType()
						if ($keyType -eq [string]) {
							if ($key -match '^\w+$' -and $key -match '^\D') {
								$script:Writer.Write('{0}{1} = ', $indent2, $key)
							}
							else {
								$script:Writer.Write("{0}'{1}' = ", $indent2, $key.Replace("'", "''"))
							}
						}
						elseif ($keyType -eq [int]) {
							$script:Writer.Write('{0}{1} = ', $indent2, $key)
						}
						elseif ($keyType -eq [long]) {
							$script:Writer.Write('{0}{1}L = ', $indent2, $key)
						}
						else {
							throw "Not supported key type '$($keyType.FullName)'."
						}
						Write-Psd $e.Value ($Depth + 1) -NoIndent
					}
					$script:Writer.WriteLine("$indent1}")
				}
				else {
					$script:Writer.WriteLine('@{}')
				}
				return
			}
			elseif ($Object -is [System.Collections.IEnumerable]) {
				$script:Writer.Write('@(')
				$empty = $true
				foreach($e in $Object) {
					if ($empty) {
						$empty = $false
						$script:Writer.WriteLine()
					}
					Write-Psd $e ($Depth + 1)
				}
				if ($empty) {
					$script:Writer.WriteLine(')')
				}
				else {
					$script:Writer.WriteLine("$indent1)" )
				}
				return
			}
			elseif ($Object -is [PSCustomObject] -or $script:Depth) {
				$script:Writer.WriteLine('@{')
				$indent2 = $script:Indent * ($Depth + 1)
				foreach($e in $Object.PSObject.Properties) {
					$key = $e.Name
					if ($key -match '^\w+$' -and $key -match '^\D') {
						$script:Writer.Write('{0}{1} = ', $indent2, $key)
					}
					else {
						$script:Writer.Write("{0}'{1}' = ", $indent2, $key.Replace("'", "''"))
					}
					Write-Psd $e.Value ($Depth + 1) -NoIndent
				}
				$script:Writer.WriteLine("$indent1}" )
				return
			}
		}
		String {
			$script:Writer.WriteLine("'{0}'", $Object.Replace("'", "''"))
			return
		}
		Boolean {
			$script:Writer.WriteLine($(if ($Object) {'$true'} else {'$false'}))
			return
		}
		DateTime {
			$script:Writer.WriteLine("[DateTime] '{0}'", $Object.ToString('o'))
			return
		}
		Char {
			$script:Writer.WriteLine("'{0}'", $Object.Replace("'", "''"))
			return
		}
		DBNull {
			$script:Writer.WriteLine('$null')
			return
		}
		default {
			if ($type.IsEnum) {
				$script:Writer.WriteLine("'{0}'", $Object)
			}
			else {
				$script:Writer.WriteLine($Object)
			}
			return
		}
	}

	throw "Not supported type '{0}'." -f $type.FullName
}

function Write-XmlChild($elem, $Depth=0) {
	foreach($e in $elem.ChildNodes) {
		Write-XmlElement $e $Depth
	}
}

function Write-XmlElement($elem, $Depth=0) {
	switch($elem.Name) {
		NewLine {
			$script:Writer.WriteLine()
			$script:LineStarted = $false
			break
		}
		Comment {
			Write-Text $elem.InnerText
			break
		}
		Table {
			Write-Text '@{'
			Write-XmlChild $elem ($Depth + 1)
			Write-Text '}'
			break
		}
		Array {
			Write-Text '@('
			Write-XmlChild $elem ($Depth + 1)
			Write-Text ')'
			break
		}
		Item {
			if ($elem.GetAttribute('Type') -eq 'String') {
				Write-Text ("'{0}' =" -f $elem.Key.Replace("'", "''"))
			}
			else {
				Write-Text ('{0} =' -f $elem.Key)
			}
			Write-XmlChild $elem $Depth
			break
		}
		Number {
			Write-Text $elem.InnerText
			break
		}
		String {
			if ($elem.GetAttribute('Type') -eq '1') {
				Write-Text "@'"
				$script:Writer.WriteLine()
				$script:Writer.Write($elem.InnerText)
				$script:Writer.WriteLine()
				$script:Writer.Write("'@")
			}
			else {
				Write-Text ("'{0}'" -f $elem.InnerText.Replace("'", "''"))
			}
			break
		}
		Variable {
			Write-Text ('${0}' -f $elem.InnerText)
			break
		}
		Cast {
			Write-Text ($elem.GetAttribute('Type'))
			Write-XmlChild $elem $Depth
			break
		}
		Comma {
			Write-Text ',' -NoSpace
			break
		}
		Semicolon {
			Write-Text ';' -NoSpace
			break
		}
		default {
			throw "Unexpected node '$_'."
		}
	}
}

function New-PsdXml($Script) {
	$err = $null
	$tokens = [System.Management.Automation.PSParser]::Tokenize($script, [ref]$err)
	if ($err) {
		$err = $err[0]
		$t1 = $err.Token
		throw 'Parser error at {0}:{1} : {2}' -f $t1.StartLine, $t1.StartColumn, $err.Message
	}

	$indent = ''
	$lastLine = 0
	foreach($t1 in $tokens) {
		if ($t1.StartLine -eq $lastLine -or $t1.Type -eq 'NewLine' -or $t1.Type -eq 'Comment') {continue}
		if ($t1.StartColumn -eq 2) {$indent = '1'; break}
		if ($t1.StartColumn -eq 3) {$indent = '2'; break}
		if ($t1.StartColumn -gt 1) {break}
		$lastLine = $t1.StartLine
	}

	$xml = [xml]'<Data/>'
	if ($indent) {
		$xml.DocumentElement.SetAttribute('Indent', $indent)
	}

	$script:Queue = [System.Collections.Queue]$tokens
	$script:Script = $Script
	try {
		Add-Data $xml.DocumentElement
		$xml
	}
	finally {
		$script:Queue = $null
		$script:Script = $null
	}
}

# Add just one String, Number, Variable, Table, or Array.
function Add-Value($elem, $t1) {
	switch($t1.Type) {
		String {
			$e = Add-XmlElement $elem String
			$e.InnerText = $t1.Content
			if ($script:Script[$t1.Start] -eq '@' -and $script:Script[$t1.Start + 1] -eq "'") {
				$e.SetAttribute('Type', 1)
			}
			break
		}
		Number {
			$e = Add-XmlElement $elem Number
			$e.InnerText = $t1.Content
			break
		}
		Variable {
			$e = Add-XmlElement $elem Variable
			$e.InnerText = $t1.Content
			break
		}
		GroupStart {
			switch($t1.Content) {
				'@{' {
					$e = Add-XmlElement $elem Table
					Add-Table $e
				}
				'@(' {
					$e = Add-XmlElement $elem Array
					Add-Array $e
				}
				default {
					ThrowUnexpectedToken $t1
				}
			}
			break
		}
		Type {
			$e = Add-XmlElement $elem Cast
			$v = $t1.Content
			#! v2 has no []
			$e.SetAttribute('Type', $(if ($v[0] -eq '[') {$v} else {"[$v]"}))
			$t2 = $script:Queue.Dequeue()
			Add-Value $e $t2
		}
		default {
			ThrowUnexpectedToken $t1
		}
	}
}

# Add data to the array element.
function Add-Array($elem) {
	while($script:Queue.Count) {
		$t1 = $script:Queue.Dequeue()
		switch($t1.Type) {
			GroupEnd {
				return
			}
			NewLine {
				$null = Add-XmlElement $elem NewLine
				break
			}
			Comment {
				$e = Add-XmlElement $elem Comment
				$e.InnerText = $t1.Content
				break
			}
			StatementSeparator {
				$null = Add-XmlElement $elem Semicolon
				break
			}
			Operator {
				if ($t1.Content -eq ',') {
					$null = Add-XmlElement $elem Comma
				}
				else {
					ThrowUnexpectedToken $t1
				}
				break
			}
			default {
				Add-Value $elem $t1
			}
		}
	}
}

# Add one item to the table element.
function Add-Item($elem, $t1, $Type) {
	$elem = Add-XmlElement $elem Item
	$elem.SetAttribute('Key', $t1.Content)
	if ($Type) {
		$elem.SetAttribute('Type', $Type)
	}

	$t1 = $script:Queue.Dequeue()
	if ($t1.Type -ne 'Operator' -or $t1.Content -ne '=') {
		ThrowUnexpectedToken $t1
	}

	$valueAdded = $false
	while($script:Queue.Count) {
		$t1 = $script:Queue.Peek()
		switch ($t1.Type) {
			GroupEnd {
				return
			}
			StatementSeparator {
				return
			}
			NewLine {
				if ($valueAdded) {return}
				$null = $script:Queue.Dequeue()
				$null = Add-XmlElement $elem NewLine
				break
			}
			Comment {
				$null = $script:Queue.Dequeue()
				$e = Add-XmlElement $elem Comment
				$e.InnerText = $t1.Content
				break
			}
			Operator {
				if ($t1.Content -eq ',') {
					$valueAdded = $false
					$null = $script:Queue.Dequeue()
					$null = Add-XmlElement $elem Comma
				}
				else {
					ThrowUnexpectedToken $t1
				}
				break
			}
			default {
				$null = $script:Queue.Dequeue()
				$valueAdded = $true
				Add-Value $elem $t1
			}
		}
	}
}

function Add-Table($elem) {
	while($script:Queue.Count) {
		$t1 = $script:Queue.Dequeue()
		switch($t1.Type) {
			GroupEnd {
				return
			}
			NewLine {
				$null = Add-XmlElement $elem NewLine
				break
			}
			Comment {
				$e = Add-XmlElement $elem Comment
				$e.InnerText = $t1.Content
				break
			}
			StatementSeparator {
				$null = Add-XmlElement $elem Semicolon
				break
			}
			Member {
				Add-Item $elem $t1
				break
			}
			String {
				Add-Item $elem $t1 -Type String
				break
			}
			Number {
				Add-Item $elem $t1 -Type Number
				break
			}
			default {
				ThrowUnexpectedToken $t1
			}
		}
	}
}

function Add-Data($elem) {
	while($script:Queue.Count) {
		$t1 = $script:Queue.Dequeue()
		switch($t1.Type) {
			NewLine {
				$null = Add-XmlElement $elem NewLine
				break
			}
			Comment {
				$e = Add-XmlElement $elem Comment
				$e.InnerText = $t1.Content
				break
			}
			StatementSeparator {
				$null = Add-XmlElement $elem Semicolon
				break
			}
			Operator {
				if ($t1.Content -eq ',') {
					$null = Add-XmlElement $elem Comma
				}
				else {
					ThrowUnexpectedToken $t1
				}
				break
			}
			default {
				Add-Value $elem $t1
			}
		}
	}
}

function Write-Text($Text, [switch]$NoSpace) {
	if ($script:LineStarted) {
		if (!$NoSpace) {
			$script:Writer.Write(' ')
		}
	}
	else {
		$script:LineStarted = $true
		$script:Writer.Write($script:Indent * $Depth)
	}
	$script:Writer.Write($Text)
}

function New-TablePsd($node) {
	$r = [System.Collections.Specialized.OrderedDictionary]([System.StringComparer]::OrdinalIgnoreCase)
	foreach($node in $node.ChildNodes) {switch($node.Name) {
		NewLine {break}
		Item {
			if ($node.GetAttribute('Type') -eq 'Number') {
				$key = New-NumberPsd $node.Key
			}
			else {
				$key = $node.Key
			}
			$r.Add($key, (New-ItemPsd $node))
			break
		}
		Comment {break}
		Semicolon {break}
		default {
			throw "Table has not supported node '$($node.Name)'."
		}
	}}
	$r
}

function New-ItemPsd($node) {
	foreach($node in $node.ChildNodes) {switch($node.Name) {
		Comma {break}
		NewLine {break}
		Comment {break}
		default {Get-Psd $node}
	}}
}

function New-ArrayPsd($node) {
	$r = [System.Collections.Generic.List[object]]@()
	foreach($node in $node.ChildNodes) {switch($node.Name) {
		NewLine {break}
		String {$r.Add($node.InnerText); break}
		Number {$r.Add((New-NumberPsd $node.InnerText)); break}
		Variable {$r.Add((New-VariablePsd $node.InnerText)); break}
		Table {$r.Add((New-TablePsd $node)); break}
		Cast {$r.Add((New-CastPsd $node)); break}
		Comma {break}
		Comment {break}
		Semicolon {break}
		default {throw "Array contains not supported node '$_'."}
	}}
	, $r
}

function New-NumberPsd($Text) {
	$r = $null
	if ([int]::TryParse($Text, [ref]$r)) {return $r}
	if ([long]::TryParse($Text, [ref]$r)) {return $r}
	if ([double]::TryParse($Text, [ref]$r)) {return $r}
	if ($Text.StartsWith('0x') -or $Text.StartsWith('0X')) {
		if ([int]::TryParse($Text.Substring(2), 'AllowHexSpecifier', $null, [ref]$r)) {return $r}
		if ([long]::TryParse($Text.Substring(2), 'AllowHexSpecifier', $null, [ref]$r)) {return $r}
	}
	throw "Not supported number '$Text'."
}

function New-VariablePsd($Text) {
	switch($Text) {
		false {return $false}
		true {return $true}
		null {return $null}
		default {throw "Not supported variable '$_'."}
	}
}

function New-CastPsd($node) {
	$typeName = $node.Type.TrimEnd(']').TrimStart('[')
	$type = [System.Management.Automation.LanguagePrimitives]::ConvertTo($typeName, [type])
	if ([type]::GetTypeCode($type) -eq 'Object') {throw "Cast to not supported type '$typeName'."}
	[System.Management.Automation.LanguagePrimitives]::ConvertTo($node.InnerText, $type)
}

Export-ModuleMember -Function @(
	'Convert-PsdToXml'
	'ConvertTo-Psd'
	'Convert-XmlToPsd'
	'Export-PsdXml'
	'Get-Psd'
	'Import-Psd'
	'Import-PsdXml'
	'Set-Psd'
)

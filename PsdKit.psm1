
$ErrorActionPreference = 1

#.ExternalHelp PsdKit-Help.xml
function Convert-PsdToXml {
	[OutputType([xml])]
	param(
		[Parameter(Position=0, Mandatory=1, ValueFromPipeline=1)]
		[string] $InputObject
	)
	process {
		trap {ThrowTerminatingError($_)}
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
	trap {ThrowTerminatingError($_)}

	if (!$Indent) {
		if (!($doc = $Xml.OwnerDocument)) {$doc = $Xml}
		if ($attr = $doc.DocumentElement.GetAttribute('Indent')) {$Indent = $attr}
	}
	$Indent = Convert-Indent $Indent

	$script:Indent = $Indent
	$script:LineStarted = $false
	$writer = New-Object System.IO.StringWriter
	if ($Xml.NodeType -ceq 'Document') {
		Write-XmlChild $Xml.DocumentElement
	}
	elseif ($Xml.Name -ceq 'Item') {
		Write-XmlChild $Xml
	}
	else {
		Write-XmlElement $Xml
	}
	$writer.ToString()
}

#.ExternalHelp PsdKit-Help.xml
function ConvertTo-Psd {
	[OutputType([String])]
	param(
		[Parameter(Position=0, ValueFromPipeline=1)]
		$InputObject,
		[string] $Indent
	)
	begin {
		$objects = [System.Collections.Generic.List[object]]@()
	}
	process {
		$objects.Add($InputObject)
	}
	end {
		trap {ThrowTerminatingError($_)}

		$Indent = Convert-Indent $Indent
		$script:Indent = $Indent

		$writer = New-Object System.IO.StringWriter
		foreach($object in $objects) {
			Write-Psd $object
		}
		$writer.ToString().TrimEnd()
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
	trap {ThrowTerminatingError($_)}
	$Path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
	[System.IO.File]::WriteAllText($Path, (Convert-XmlToPsd $Xml -Indent $Indent), ([System.Text.Encoding]::UTF8))
}

#.ExternalHelp PsdKit-Help.xml
function Get-PsdXml {
	param(
		[Parameter(Position=0, Mandatory=1)]
		[System.Xml.XmlNode] $Xml,
		[Parameter(Position=1)]
		[string] $XPath
	)
	trap {ThrowTerminatingError($_)}
	if ($XPath) {
		$node = $xml.SelectSingleNode($XPath)
		if (!$node) {throw "XPath selects nothing: '$XPath'."}
	}
	else {
		$node = $Xml
	}
	if ($node.NodeType -ne 'Element') {throw "Unexpected node type '$($node.NodeType)'."}
	switch($node.Name) {
		Item {
			if ($node.ChildNodes.Count -ne 1) {throw "Element 'Item' must have one child node."}
			return Get-PsdXml $node.FirstChild
		}
		String {
			return $node.InnerText
		}
		Number {
			return New-Number $node.InnerText
		}
		Variable {
			return New-Variable $node.InnerText
		}
		Comment {
			return $node.InnerText
		}
		Array {
			return New-Array $node
		}
		Table {
			return New-Table $node
		}
		Cast {
			return New-Cast $node
		}
		default {
			throw "Not supported element '$_'."
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
	trap {ThrowTerminatingError($_)}
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
	trap {ThrowTerminatingError($_)}
	$script = Get-Content -LiteralPath $Path
	New-PsdXml $script
}

#.ExternalHelp PsdKit-Help.xml
function Set-PsdXml {
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
	trap {ThrowTerminatingError($_)}
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
		$writer.Write($indent1)
	}

	if ($null -eq $Object) {
		$writer.WriteLine('$null')
		return
	}

	$type = $Object.GetType()
	switch([System.Type]::GetTypeCode($type)) {
		Object {
			if ($Object -is [System.Collections.IDictionary]) {
				if ($Object.Count) {
					$writer.WriteLine('@{')
					$indent2 = $script:Indent * ($Depth + 1)
					foreach($e in $Object.GetEnumerator()) {
						$key = $e.Key
						$keyType = $key.GetType()
						if ($keyType -eq [string]) {
							if ($key -match '^\w+$' -and $key -match '^\D') {
								$writer.Write(('{0}{1} = ' -f $indent2, $key))
							}
							else {
								$writer.Write(("{0}'{1}' = " -f $indent2, $key.Replace("'", "''")))
							}
						}
						elseif ($keyType -eq [int]) {
							$writer.Write(('{0}{1} = ' -f $indent2, $key))
						}
						elseif ($keyType -eq [long]) {
							$writer.Write(('{0}{1}L = ' -f $indent2, $key))
						}
						else {
							throw "Not supported key type '$($keyType.FullName)'."
						}
						Write-Psd $e.Value ($Depth + 1) -NoIndent
					}
					$writer.WriteLine("$indent1}" )
				}
				else {
					$writer.WriteLine('@{}')
				}
				return
			}
			elseif ($Object -is [PSCustomObject]) {
				$writer.WriteLine('@{')
				$indent2 = $script:Indent * ($Depth + 1)
				foreach($e in $Object.PSObject.Properties) {
					$key = $e.Name
					if ($key -match '^\w+$' -and $key -match '^\D') {
						$writer.Write(('{0}{1} = ' -f $indent2, $key))
					}
					else {
						$writer.Write(("{0}'{1}' = " -f $indent2, $key.Replace("'", "''")))
					}
					Write-Psd $e.Value ($Depth + 1) -NoIndent
				}
				$writer.WriteLine("$indent1}" )
				return
			}
			elseif ($Object -is [System.Collections.IList]) {
				if ($Object.Count) {
					$writer.WriteLine('@(')
					foreach($e in $Object) {
						Write-Psd $e ($Depth + 1)
					}
					$writer.WriteLine("$indent1)" )
				}
				else {
					$writer.WriteLine('@()')
				}
				return
			}
			elseif ($Object -is [System.Management.Automation.SwitchParameter]) {
				$writer.WriteLine($(if ($Object) {'$true'} else {'$false'}))
				return
			}
		}
		String {
			$writer.WriteLine("'{0}'" -f $Object.Replace("'", "''"))
			return
		}
		Boolean {
			$writer.WriteLine($(if ($Object) {'$true'} else {'$false'}))
			return
		}
		DateTime {
			$writer.WriteLine("[DateTime] '{0}'" -f $Object.ToString('o'))
			return
		}
		'Char' {
			$writer.WriteLine("'{0}'" -f $Object.Replace("'", "''"))
			return
		}
		default {
			if ($type.IsEnum) {
				$writer.WriteLine("'{0}'" -f $Object)
			}
			else {
				$writer.WriteLine($Object)
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
			$writer.WriteLine()
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
				$writer.WriteLine()
				$writer.Write($elem.InnerText)
				$writer.WriteLine()
				$writer.Write("'@")
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
			throw "Unexpected XML element '$_'."
		}
	}
}

function New-PsdXml($Script) {
	$err = $null
	$tokens = [System.Management.Automation.PSParser]::Tokenize($script, [ref]$err)
	if ($err) {
		$err = $err[0]; $t1 = $err.Token
		throw 'Parser error at {0}:{1} : {2}' -f $t1.StartLine, $t1.StartColumn, $err.Message
	}
	$queue = [System.Collections.Queue]$tokens

	$xml = [xml]'<Data/>'

	$lastLine = 0
	$inferIndent = ''
	foreach($t1 in $tokens) {
		if ($t1.StartLine -eq $lastLine) {continue}
		if ($t1.Type -eq 'NewLine' -or $t1.Type -eq 'Comment') {continue}
		if ($t1.StartColumn -eq 2) {$inferIndent = '1'; break}
		if ($t1.StartColumn -eq 3) {$inferIndent = '2'; break}
		if ($t1.StartColumn -gt 1) {break}
		$lastLine = $t1.StartLine
	}
	if ($inferIndent) {
		$xml.DocumentElement.SetAttribute('Indent', $inferIndent)
	}

	Add-Data $xml.DocumentElement
	$xml
}

# Add just one String, Number, Variable, Table, or Array.
function Add-Value($elem, $t1) {
	switch($t1.Type) {
		String {
			$e = Add-XmlElement $elem String
			$e.InnerText = $t1.Content
			if ($t1.EndLine - $t1.StartLine) {
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
			$t2 = $queue.Dequeue()
			Add-Value $e $t2
		}
		default {
			ThrowUnexpectedToken $t1
		}
	}
}

# Add data to the array element.
function Add-Array($elem) {
	while($queue.Count) {
		$t1 = $queue.Dequeue()
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

	$t1 = $queue.Dequeue()
	if ($t1.Type -ne 'Operator' -or $t1.Content -ne '=') {
		ThrowUnexpectedToken $t1
	}

	$valueAdded = $false
	while($queue.Count) {
		$t1 = $queue.Peek()
		switch ($t1.Type) {
			GroupEnd {
				return
			}
			StatementSeparator {
				return
			}
			NewLine {
				if ($valueAdded) {return}
				$null = $queue.Dequeue()
				$null = Add-XmlElement $elem NewLine
				break
			}
			Comment {
				$null = $queue.Dequeue()
				$e = Add-XmlElement $elem Comment
				$e.InnerText = $t1.Content
				break
			}
			Operator {
				if ($t1.Content -eq ',') {
					$null = $queue.Dequeue()
					$null = Add-XmlElement $elem Comma
				}
				else {
					ThrowUnexpectedToken $t1
				}
				break
			}
			default {
				$null = $queue.Dequeue()
				$valueAdded = $true
				Add-Value $elem $t1
			}
		}
	}
}

function Add-Table($elem) {
	while($queue.Count) {
		$t1 = $queue.Dequeue()
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
	while($queue.Count) {
		$t1 = $queue.Dequeue()
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
			$writer.Write(' ')
		}
	}
	else {
		$script:LineStarted = $true
		$writer.Write($script:Indent * $Depth)
	}
	$writer.Write($Text)
}

function New-Number($Text) {
	$r = $null
	if ([int]::TryParse($Text, [ref]$r)) {return $r}
	if ([long]::TryParse($Text, [ref]$r)) {return $r}
	if ([double]::TryParse($Text, [ref]$r)) {return $r}
	throw "Not supported number '$_'."
}

function New-Variable($Text) {
	switch($Text) {
		false {return $false}
		true {return $true}
		null {return $null}
		default {throw "Not supported variable '$_'."}
	}
}

function New-Cast($node) {
	$typeName = $node.Type.TrimEnd(']').TrimStart('[')
	$type = [System.Management.Automation.LanguagePrimitives]::ConvertTo($typeName, [type])
	if ([type]::GetTypeCode($type) -eq 'Object') {throw "Cast to not supported type '$typeName'."}
	[System.Management.Automation.LanguagePrimitives]::ConvertTo($node.InnerText, $type)
}

function New-Array($node) {
	$r = [System.Collections.Generic.List[object]]@()
	foreach($node in $node.ChildNodes) {
		switch($node.Name) {
			NewLine {break}
			String {$r.Add($node.InnerText); break}
			Number {$r.Add((New-Number $node.InnerText)); break}
			Variable {$r.Add((New-Variable $node.InnerText)); break}
			Table {$r.Add((New-Table $node)); break}
			Cast {$r.Add((New-Cast $node)); break}
			default {throw "Array contains not supported node '$_'."}
		}
	}
	, $r
}

function New-Table($node) {
	$r = [System.Collections.Specialized.OrderedDictionary]([System.StringComparer]::OrdinalIgnoreCase)
	foreach($node in $node.ChildNodes) {
		if ($node.Name -eq 'Item') {
			if ($node.GetAttribute('Type') -eq 'Number') {
				$key = New-Number $node.Key
			}
			else {
				$key = $node.Key
			}
			if ($node.ChildNodes.Count -ne 1) {throw "Item must have one child node."}
			$r.Add($key, (Get-PsdXml $node.FirstChild))
		}
		elseif ($node.Name -ne 'NewLine') {
			throw "Table contains not supported node '$($node.Name)'."
		}
	}
	$r
}

Export-ModuleMember -Function @(
	'Convert-PsdToXml'
	'ConvertTo-Psd'
	'Convert-XmlToPsd'
	'Export-PsdXml'
	'Get-PsdXml'
	'Import-Psd'
	'Import-PsdXml'
	'Set-PsdXml'
)

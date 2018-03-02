
# Common cases. The file must be imported and exported the same.
# Keep the first line empty.

@{
	# Variable
	Null = $null
	True = $true
	False = $false

	# Number
	Int = 42
	Hex = 0x42
	Long = 42l
	Suffix = 42mb
	Double = 3.14

	# String
	String1 = 'one line simple string'
	String2 = @'
two+ line
string as here string
'@
	# Cast
	Date = [DateTime] '2018-02-20'

	# Comma
	Array1 = $null, 42, 3.14, 'string' # end line comment

	# Array
	Array2 = @( $null, 42, 3.14, 'string' ) <# end line block comment #>

	# Semicolon
	Question = 'meaning of life'; Answer = 42;
	Table1 = @{ Question = 'meaning of life'; Answer = 42 } #!
	Table2 = @{ Question = 'meaning of life'; '''Answer''' = 42 } #!

	# nested stuff
	Array3 = @(
		@{ p1 = 1; p2 = 2 }
		@{
			Array1 = 1, 2
			Array2 = @( 1; 2 ) # use ;
		}
	)

	### Unusual cases
	NewLineAfterEqual =
	42
	NumberKeys = @{ 1 = 1; 1.1 = 2 }
}

<# Block comment #> <# many in the same line #>


<#
	Usual block comment.
	Keep two empty lines before it.
#>

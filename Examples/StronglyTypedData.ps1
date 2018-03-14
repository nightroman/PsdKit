
<#
.Synopsis
	Exports and imports using PowerShell classes and psd1 files.

.Description
	This scripts demonstrates strongly typed data logging using psd1 files:
	- Define required PowerShell classes, e.g. [Message] and related types.
	- To export, use ConvertTo-Psd with Depth + Set-Content or Add-Content.
	- To import, use Import-Psd + convert raw data to [Message[]].

	We create two messages and write them one by one to the file "z.psd1".
	The first creates the file, the second is appended to it. Then we read
	data, convert to the original type, and output [Message] objects:

	Message                Severity Location
	-------                -------- --------
	Obsolete feature.       Warning {C:\Scripts\Script1.ps1:11}
	Not supported feature.    Error {C:\Scripts\Script2.ps1:99}
#>
#requires -Version 5

# Define data types.
enum Severity {
	Information
	Warning
	Error
}
class Location {
	[string] $File
	[int] $Line
	[string] ToString() { return '{0}:{1}' -f $this.File, $this.Line }
}
class Message {
	[string] $Message
	[Severity] $Severity
	[Location] $Location
}

# Create message 1 and save it to the new file.
[Message] @{
	Message = 'Obsolete feature.'
	Severity = 'Warning'
	Location = @{ File = 'C:\Scripts\Script1.ps1'; Line = 11 }
} |
ConvertTo-Psd -Depth 2 | Set-Content z.psd1

# Create message 2 and append it to the file.
[Message] @{
	Message = 'Not supported feature.'
	Severity = 'Error'
	Location = @{ File = 'C:\Scripts\Script2.ps1'; Line = 99 }
} |
ConvertTo-Psd -Depth 2 | Add-Content z.psd1

# Import raw data and convert to the original types.
[Message[]] (Import-Psd z.psd1)

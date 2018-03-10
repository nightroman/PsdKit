
. ./About.ps1
if ($Version -le 4) {return task skip4}

task StronglyTypedData {
	($r = ../Examples/StronglyTypedData.ps1) | Out-String

	equals $r.Count 2
	equals $r[0].Message 'Obsolete feature.'
	equals $r[1].Message 'Not supported feature.'
	equals $r[0].GetType().FullName Message
	equals $r[0].Severity.ToString() Warning
	equals $r[0].Severity.GetType().FullName Severity
	equals $r[0].Location.File C:\Scripts\Script1.ps1
	equals $r[0].Location.Line 11

	Remove-Item z.psd1
}

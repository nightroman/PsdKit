
. ./About.ps1 Import-Psd

task Test01 {
	$r = Import-Psd test-01.psd1
	$r | Out-String
	equals $r.Date.GetType() ([datetime])
}

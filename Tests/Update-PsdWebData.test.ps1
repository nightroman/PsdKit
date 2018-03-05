
. ./About.ps1 Update-PsdWebData.ps1
if ($Version -eq 2) {return}
if ($Version -eq 6) {. Set-Mock Import-Module {}}

task Basic {
	Set-Content z.psd1 {
		@{
			DataUrl = 'bar'
			Data = @{}
		}
	}

	### test 1 : empty Data -> the whole object is set

	. Set-Mock Invoke-RestMethod { @{ p1 = 1; p2 = 'p2' } }
	($r = Update-PsdWebData.ps1 z.psd1)
	equals $r 'bar updated'

	$r = Import-Psd z.psd1
	equals $r.Data.Count 2
	equals $r.Data.p1 1
	equals $r.Data.p2 p2

	### test 2 : custom Data -> existing changed items are updated
	# note that p1 is not changed and new p3 is ignored

	. Set-Mock Invoke-RestMethod { @{ p1 = 1; p2 = 'p2-new'; p3 = 'extra' } }
	($r = Update-PsdWebData.ps1 z.psd1)
	equals $r 'bar p2 p2 -> p2-new'

	$r = Import-Psd z.psd1
	equals $r.Data.Count 2
	equals $r.Data.p1 1
	equals $r.Data.p2 p2-new

	### test 3 : missing data -> existing items are set to $null

	. Set-Mock Invoke-RestMethod { @{ p1 = 1 } }
	($r = Update-PsdWebData.ps1 z.psd1)
	equals $r 'bar p2 p2-new -> '

	$r = Import-Psd z.psd1
	equals $r.Data.Count 2
	equals $r.Data.p1 1
	equals $r.Data.p2 $null

	Remove-Item z.psd1
}

task MissingPath {
	($r = try {Update-PsdWebData.ps1 missing.psd1} catch {$_})
	equals "$r" "Cannot find path 'missing.psd1' because it does not exist."
	equals $r.FullyQualifiedErrorId Update-PsdWebData.ps1
}

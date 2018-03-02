
. ./About.ps1 ConvertTo-Psd

task Indent {
	# 2 spaces as 2
	($r = ConvertTo-Psd @{x=1} -Indent 2)
	Test-Hash $r 9a0cd32559172d5f6aa0897c77e72064

	# 3 spaces as string
	($r = ConvertTo-Psd @{x=1} -Indent '   ')
	Test-Hash $r 501a6d93880811af350d8dbb33c84c06

	# 4 spaces default
	($r = ConvertTo-Psd @{x=1})
	Test-Hash $r 75e606b3d43e410e849cde5b048860bb

	# 4 spaces as 4
	($r = ConvertTo-Psd @{x=1} -Indent 4)
	Test-Hash $r 75e606b3d43e410e849cde5b048860bb

	# tab as 1
	($r = ConvertTo-Psd @{x=1} -Indent 1)
	Test-Hash $r 838429fa71b915d95172f5d2798d15a8
}

task Assorted {
	$data = @(
		$null
		'bar1'
		42
		99d
		3.14
		$true
		$false
		[datetime]'2018-02-19'
		,@(1, "'bar'")
		@{
			array = 1, 2, @{p1=1; p2=2}
			table = @{p1=1; p2=1,2}
			emptyArray = @()
			emptyTable = @{}
			"1'key'" = 42
			2 = 'int key'
			3L = 'long key'
		}
	)

	($r = $data | ConvertTo-Psd)
	Test-Hash $r 0d899f109288daa3a582e33ff638e885
}

task DateTime {
	$data = @{
		Date1 = [datetime]'2018-02-19'
		Date2 = [datetime]636545952000000000
	}

	($r = ConvertTo-Psd $data)
	Test-Hash $r 63799421b5537207779b7383870e18f9

	$r = Invoke-Expression $r
	$date = [datetime]'2018-02-19'
	equals $date $r.Date1
	equals $date $r.Date2
}

task PSCustomObject {
	$data = 1 | Select-Object name, array, object
	$data.name = 'bar'
	$data.array = 1, 2
	$data.object = 1 | Select-Object name, value
	$data.object.name = 'bar2'
	$data.object.value = 42
	($r = ConvertTo-Psd $data)
	Test-Hash $r a7e67885e0e41a8be8ef93d2a95223ec
}

#! In v2, Get-Date results in "not supported type Microsoft.PowerShell.Commands.DisplayHintType"
#! [DateTime]::Now is fine in all versions
task LoggingExample {
	# new log
    @{time = [DateTime]::Now; text = 'text1'} | ConvertTo-Psd | Set-Content z.psd1
    # append log
    @{time = [DateTime]::Now; text = 'text2'} | ConvertTo-Psd | Add-Content z.psd1
    @{time = [DateTime]::Now; text = 'text3'} | ConvertTo-Psd | Add-Content z.psd1

    # read log
    ($r = Import-Psd z.psd1)
    equals $r.Count 3
    equals $r[0].text text1
    equals $r[1].text text2
    equals $r[2].text text3

    Remove-Item z.psd1
}

task JsonToPsd -If ($Version -ge 5) {
	$json = ConvertTo-Json ([PSCustomObject]@{
		string = 'bar'
		number = 42
		array = 1, 2
	})

	($r = $json | ConvertFrom-Json | ConvertTo-Psd)
	Test-Hash $r f550e9ceb0df2caf8eddba1f50a1d64c
}

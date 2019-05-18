
. ./About.ps1 Import-Psd

task Test01 {
	$r = Import-Psd test-01.psd1
	$r | Out-String
	equals $r.Date.GetType() ([datetime])
}

# https://github.com/nightroman/PsdKit/issues/7
task MergeInto {
	# existing data
	$data = @{
		MyExtraString = 'MyExtraString'
		String1 = 'will be replaced'
	}

	# import and merge into existing
	$r = Import-Psd test-01.psd1 -MergeInto $data

	# nothing is returned
	equals $r $null

	# extra is the same
	equals $data.MyExtraString MyExtraString

	# same is replaced
	equals $data.String1 'one line simple string'

	# new is added
	equals $data.Int 42
}

task ImportMixed {
	$r = Import-Psd test-02.psd1
	$r | Out-String
	equals ($r.GetType()) ([object[]])
	equals $r.Count 3
	equals $r[0] 42
	equals $r[1] string
	equals $r[2].Int 42
	equals $r[2].String string
}

task CannotMergeMixed {
	$data = @{}
	($r = try {Import-Psd test-02.psd1 -MergeInto $data} catch {$_})
	assert (($r | Out-String) -like '*With Merge imported data must be a hastable.*try {Import-Psd *')
}

# With -Unsafe any data can be imported because the source is actually invoked.
task ImportPsdUnsafe {
	# unsafe import
	$r = Import-Psd test-03.psd1 -Unsafe

	# usual data
	equals $r.Id 1

	# trivial script block
	equals ($r.Block.GetType()) ([scriptblock])
	equals (& $r.Block) 42

	# complex script block
	equals ($r.Complex.GetType()) ([scriptblock])
	$r = & $r.Complex 42
	equals $r[0] 42
	equals $r[1].Id 42
}

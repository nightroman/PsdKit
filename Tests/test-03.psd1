# Unsafe data with script blocks

@{
	Id = 1
	Block = {42}
	Complex = {
		param($x)
		@($x)
		@{id=$x}
	}
}

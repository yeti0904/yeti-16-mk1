set f 0
set d 1
set b 0

jmp nextIt

loop:
	dec d
	cmp d b
	jnz nextIt
	jmp loop

nextIt:
	lda ds 1029
	set c 64000
	setl f
	inc f
	set d 100
	jmp loop

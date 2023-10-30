set a 0
loop:
	lda ds 1029
	set c 64000
	setl a
	inc a
	jmp loop

set f 0
set d 65535
set b 0

jmpb nextIt

loop:
	dec d
	cmp d b
	; uncomment the following code if you want to see every colour ever flash in front
	; of you, so consider this an epilepsy warning
	;jnz nextIt
	jmpb loop

nextIt:
	lda ds 1029
	set c 64000
	setl f
	inc f
	set d 100
	jmpb loop

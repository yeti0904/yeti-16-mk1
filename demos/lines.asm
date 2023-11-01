lda ds 1029
set c 64000

loop:
	cpp ab ds
	set d 2
	mod b d
	set d 0
	cmp b d
	jnz draw_black
	set b 15
	jmp next

draw_black:
	set b 0

next:
	wrb ds b
	incp ds
	dec c
	set b 0
	cmp c b
	jnz end
	jmp loop

end:
	jmp end

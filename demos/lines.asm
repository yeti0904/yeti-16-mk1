set a 2
set b 80
out a b
lda ds 1029
set c 64000

loop:
	cpp ab ds
	set d 2
	mod b d
	set d 0
	cmp b d
	jnzb draw_black
	set b 15
	jmpb next

draw_black:
	set b 0

next:
	wrb ds b
	incp ds
	dec c
	set b 0
	cmp c b
	jnzb end
	jmpb loop

end:
	jmpb end

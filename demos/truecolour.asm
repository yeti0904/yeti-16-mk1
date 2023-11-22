lda ds 0x000404
set a 0x12
wrb ds a ; Sets video mode

set a 2
set b 77
out a b ; make graphics controller update display

lda ds 0x000405
set c 64000
set d 255

loop:
	wrb ds d
	incp ds
	wrb ds d
	incp ds
	wrb ds d
	incp ds
	inc d
	dec c
	set a 0
	cmp c a
	jzb loop

end:
	jmpb end

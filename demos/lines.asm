; load palette using YETI-16 graphics controller
set a 2
set b 80
out a b

; 1029 is where VRAM is
lda ds 1029
; 64000 is the area of the display
set c 64000

loop:
	; check if current pixel coordinate is even or odd
	cpp ab ds
	set d 2
	mod b d
	set d 0
	cmp b d
	; draws black if its even
	jnzb draw_black
	; and white if its odd
	set b 15
	jmpb next

draw_black:
	set b 0

next:
	; writes the current colour to the display
	wrb ds b
	incp ds
	dec c
	set b 0
	; checks if rendered every pixel
	cmp c b
	jnzb end
	jmpb loop

end:
	jmpb end

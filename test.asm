; set video mode to 80x40 text mode (mode 0x00)
lda ds 1028
set a 0
wrb ds a
set a 2
set b 77
out a b

; load font
set a 2
set b 70
out a b

end:
	jmpb end

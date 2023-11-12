lda bs 0x100000
lda ds 1029
set a 0
set c 3200
setl a
lda ds 1029
set a 65
wrb ds a

end:
	jmpb end

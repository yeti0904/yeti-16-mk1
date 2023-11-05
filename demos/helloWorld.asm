; change to text mode (40x40 cells, 8x8 font)
lda ds 1028
set a 1
wrb ds a
set a 2
set b 77
out a b
set a 2
set b 70
out a b

; the assembler has no way to store data so this is the best i can do for now
lda ds 1029
set c 1600
set a 32
setl a
lda ds 1029
set a 72
wrb ds a
incp ds
set a 101
wrb ds a
incp ds
set a 108
wrb ds a
incp ds
set a 108
wrb ds a
incp ds
set a 111
wrb ds a
incp ds
set a 44
wrb ds a
incp ds
set a 32
wrb ds a
incp ds
set a 119
wrb ds a
incp ds
set a 111
wrb ds a
incp ds
set a 114
wrb ds a
incp ds
set a 108
wrb ds a
incp ds
set a 100
wrb ds a
incp ds
set a 33
wrb ds a

loop:
	jmp loop

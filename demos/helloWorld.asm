; set video mode to 80x25 text mode (mode 0x00)
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

; load palette
set a 2
set b 80
out a b

; set screen colours to white text on blue background
set a 0x4F
lda ds 0x18B5
set c 3200
setl a

; the assembler has no way to store data so this is the best i can do for now
lda ds 1029
set c 3200
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

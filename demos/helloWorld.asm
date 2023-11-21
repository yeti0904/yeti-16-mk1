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

; load palette
set a 2
set b 80
out a b

; set screen colours to white text on blue background
set a 0x4F
lda ds 0x18B5
set c 3200
setl a

; clear screen
lda ds 1029
set c 3200
set a 32
setl a

; now to print hello world
lda ds 1029
lda sr string

loop:
	rdb sr
	jz .end
	wrb ds a
	incp ds
	incp sr
	jmp loop
.end:
	jmp .end

string:
	db "hello world" 0

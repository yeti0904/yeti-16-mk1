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

; set screen colours to white text on black background
set a 0x0F
lda ds 0x18B5
set c 3200
setl a

; clear screen
lda ds 1029
set c 3200
set a 32
setl a

; load interrupt
lda ds 4
set a 255
wrb ds a ; enables interrupt
lda ds 5
lda ab interrupt_handler
wra ds ab ; puts interrupt in table

; call interrupt
int 0
end:
	jmp end

interrupt_handler:
	lda ds 1029
	set a 65
	wrb ds a
	ret

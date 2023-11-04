; Variables
; D = device

keyboard:
	; checks if any key events are available
	set d 1
	chk d
	jnz print
	; jumps back to keyboard if there are none available
	jmp keyboard

print:
	; skip event type
	in d
	in d
	set d 0
	set c 80
	; use debug device to print to the console
	out d c
	out d a
	jmp keyboard

; Variables
; D = device

keyboard:
	set d 1
	chk d
	jnz print
	jmp keyboard

print:
	in d
	in d
	set d 0
	set c 80
	out d c
	out d a
	jmp keyboard

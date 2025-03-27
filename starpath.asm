; Starpath is not 55 bytes
; Screen 3 raycasting demo for MSX Turbo R
; Start by typing the following in BASIC: BLOAD"STARPATH.BIN",R
; Assumes R800 is enabled!
; Based on: https://hellmood.111mb.de/starpath_is_55_bytes.html


	OUTPUT "starpath.bin"
	
WRTVDP: equ $47
CHGMOD: equ $5F
GTSTCK: equ $D5
NSTWRT: equ $171
NWRVRM: equ $177
CHGCPU: equ $180
NEWKEY: equ $FBE5

	db $fe
	dw init, end, init
	
	org $c000
	
init:
	ld a,3
	call CHGMOD
	
	ld bc,1 * 256 + 16
	call WRTVDP
	
	ld bc,30 * 256 + $9a
	ld hl,palette
output_palette:
	outi
	dec hl
	outi
	jr nz,output_palette

	ld d,b
	inc b

frame:
	ld c,$2c			; inc ixl
	ld a,(NEWKEY + 8)
	rlca
	jr nc,forward
	rlca
	jr nc,down
	rlca
	jr nc,up
	rlca
	jr c,none

backward:
	inc c				; dec ixl
forward:
	ld a,c
	ld (update_timer + 1),a
	dec b

down:
	ld a,b
	inc b
	cp 22
	jr c,none

up:
	dec b
	jr nz,none
	inc b

none:
	exx

	ld hl,0				; vram address 0
	ld bc,8 * 256 + 4	; set R#4 to 8 (8 * $800 = $4000)
	push bc				; push seed for random number generator
	
	ld a,ixl
	rrca
	jr c,page0
page1:
	ld h,64				; vram address $4000
	ld b,l				; set R#4 to 0
page0:
	call NSTWRT			; set VRAM write to invisible page

	call WRTVDP			; swap display page
	
	ld b,l				; B = Y
	ld c,l				; C = X
	jr loop_even


loop_y:
	sub 32
	ld b,a
	jr loop_even

pixel_ray:
	exx
	sub 32
	rrca
	and 15
pixel_sky:
	ld l,a
pixel_star:	
	ld a,ixh			; get value from color accumulator
	add a,a
	add a,a
	add a,a
	add a,a
	add a,l
	
	bit 2,c
	jr z,loop_odd
	
	out ($98),a

	res 2,c				; 4x dec c
	
	ld a,b
	add a,4
	ld b,a
	
	and %00011111
	jr nz,loop_even
	
	ld a,c
	add a,8
	ld c,a
	ld a,b
	jr nz,loop_y
	cp 192
	jr c,loop_even

update_timer:
	inc ixl
	
	exx
	pop hl				; remove seed from stack
	jr frame



loop_odd:
	ld ixh,a			; set new color in color accumulator
	set 2,c				; 4x inc c

loop_even:
	pop hl				; pop seed
; 16-bit xorshift pseudorandom number generator by John Metcalf
random:
	ld a,h
	rra
	ld a,l
	rra
	xor h
	ld h,a
	ld a,l
	rra
	ld a,h
	rra
	xor l
	ld l,a
	xor h
	ld h,a
	
	push hl				; push seed
	
	ex af,af'			; keep the MSB of the generated random number in A'

	ld d,14				; D = depth
	
	ld a,c
	sub d
	jr c,sky
	
	mulub a,d			; HL = xp

	sub 15
	ld e,a
	sbc a,a
	ld d,a				; DE = xp diff

	ld a,b
	exx
	mulub a,b			; HL' = yp
	ld e,a				; DE' = yp diff
	
	ld c,ixl			; C' = dx
	sla c
	exx
	
ray:
	ld a,h				; xp
	exx
	or h				; yp
	and c				; dx
	bit 4,a
	jr nz,pixel_ray
	
	add hl,de
	inc c
	exx
	adc hl,de
	dec de
	dec de
	jr nz,ray

sky_or_star:
	ex af,af'			; get the generated random number from A'
	ld l,7
	cp l
	jr c,pixel_star

sky:
	ld a,b
	add a,16
	and %11110000
	rrca
	rrca
	rrca
	rrca
	jp p,pixel_sky
	xor 15
	dec a
	jr pixel_sky
	

palette:
	db $11
	db $22
	db $33
	db $44
	db $55
	db $66
	db $77
	db $10
	db $30
	db $50
	db $70
	db $01
	db $02
	db $03
	db $04

end:

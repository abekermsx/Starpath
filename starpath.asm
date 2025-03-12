; Starpath is not 55 bytes
; Screen 3 raycasting demo for MSX Turbo R
; Start by typing the following in BASIC: BLOAD"STARPATH.BIN",R
; Assumes R800 is enabled!
; Based on: https://hellmood.111mb.de/starpath_is_55_bytes.html


	OUTPUT "starpath.bin"
	
WRTVDP: equ $47
CHGMOD: equ $5F
NSTWRT: equ $171
NWRVRM: equ $177
CHGCPU: equ $180

	db $fe
	dw init, end, init
	
	org $c000
	
init:
	ld a,3
	call CHGMOD
	
	ld a,8
	ld hl,$3800
	call NWRVRM
	
	ld h,$1b
	call NSTWRT
	
	ld bc,32 * 256 + $98
	ld de,7
	ld hl,8 * 256 + 127
loop:
	ld a,r
	xor b
	and l
	sub 4
	jr c,loop1
	out (c),d
	out (c),a
	xor a
	out (c),a
	out (c),e
	ld a,r
	and 3
	add a,h
	add a,d
	ld d,a
loop1:
	dec h
	jr nz,loop2
	ld h,8
	srl l
loop2:
	djnz loop
	
	ld bc,1 * 256 + 16
	call WRTVDP
	
	ld bc,32 * 256 + $9a
	ld hl,palette
	otir

	ld d,b
	ld b,14
	exx
	
frame:
	ld hl,0				; vram address 0
	ld bc,8 * 256 + 4	; set R#4 to 8 (8 * $800 = $4000)
	
	ld a,ixl
	and 2
	jr z,page0
page1:
	ld h,64				; vram address $4000
	ld b,l				; set R#4 to 0
page0:
	call NSTWRT			; set VRAM write to invisible page

	call WRTVDP			; swap display page
	
	ld b,l				; B = Y
	ld c,l				; C = X
	jr loop_even


pixel_ray:
	exx
	sub 32
	srl a
	and 15
pixel_sky:
	ld l,a
	ld a,ixh			; get value from color accumulator
	add a,a
	add a,a
	add a,a
	add a,a
	add a,l
	
	bit 2,c
	jr z,loop_odd
	
	out ($98),a

	res 2,c		; 4x dec c
	
	ld a,b
	add a,4
	ld b,a
	
	and %00011111
	jr nz,loop_even
	
	ld a,b
	sub 32
	ld b,a
	
	ld a,c
	add a,8
	ld c,a
	jr nz,loop_even
	
	ld a,b
	add a,32
	ld b,a
	
	cp 192
	jr c,loop_even
	
	inc ixl			; increase time
	inc ixl
	jr frame
	
	
loop_odd:
	ld ixh,a		; set new color in color accumulator
	set 2,c			; 4x inc c

loop_even:
	ld d,14			; D = depth
	
	ld a,c
	sub d
	jr c,sky
	
	mulub a,d		; HL = xp

	sub 15
	ld e,a
	sbc a,a
	ld d,a			; DE = xp diff

	ld a,b
	exx
	mulub a,b		; HL' = yp
	ld e,a			; DE' = yp diff
	
	ld c,ixl		; C' = dx
	exx
	
ray:
	ld a,h			; xp
	exx
	or h			; yp
	and c			; dx
	bit 4,a
	jr nz,pixel_ray
	
	add hl,de
	inc c
	exx
	adc hl,de
	jr z,sky
	dec de
	dec de
	jr ray

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
	db $11,$01
	db $22,$02
	db $33,$03
	db $44,$04
	db $55,$05
	db $66,$06
	db $77,$07
	db $11,$00
	db $33,$00
	db $55,$00
	db $77,$00
	db $01,$01
	db $02,$02
	db $03,$03
	db $04,$04
	
end:

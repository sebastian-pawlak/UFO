; "UFO", Atari XL/XE Intro 256B
; code by tr1x
; requirements: original Atari XL/XE 64KB PAL
; version: 1.0
; release date: 2019-12-07

	org $600

;debug	equ 1		; for graphics preview of diagonal lines
offset	equ 0		; display list offset, used for preview only

vertlin	equ $b5		; number of vertical lines
memdl1	equ $0058	; we do believe that the initial value = #>dlist
memdl2	equ $00cd
memvp1	equ $00cf
memdbg1	equ $00d5
memdbg2	equ $00d7
vdslst	equ $0200
vvblkd	equ $0224
sdmctl	equ $022f
pcolr0	equ $02c0
pcolr1	equ $02c1
pcolr2	equ $02c2
color2	equ $02c6
vidptr	equ $4000	; video memory
dlist	equ $9c20	; display list
hposp0	equ $d000
hposp1	equ $d001
hposp2	equ $d002
colpm1	equ $d013
colpf1	equ $d017
gractl	equ $d01d
random	equ $d20a
pmbase	equ $d407
wsync	equ $d40a
vcount	equ $d40b
nmien	equ $d40e
setvbv	equ $e45c
xitvbv	equ $e462

	; prepare display list
	lda #<dlist+3
	sta memdl1
	;lda #>dlist
	;sta memdl1+1
	ldx #vertlin
	ldy #$00
loopa1	lda #$4f	; ANTIC command: gr.mode | address
	sta (memdl1),y
	inc memdl1
	;bne skipb1	; not needed,
	;inc memdl1+1	; ..since does not occur in practice
skipa1	lda random
	pha
	and #%11000000	; $..00, $..40, $..80, $..c0
	sta (memdl1),y
	inc memdl1
	bne skipa2
	inc memdl1+1
skipa2	pla
	and #%00111111
	;clc		; not needed in practice
	adc #>vidptr
	sta (memdl1),y
	inc memdl1
	bne skipa3
	inc memdl1+1
skipa3	dex
	bne loopa1

	;lda #$41	; jump to the beginning of display list
	;sta dlist+$243	; ..is not necessary
	;lda #<dlist
	;sta dlist+$244
	;lda #>dlist
	;sta dlist+$245

	; draw diagonal line #1
	jsr draw

	; set PMG
	lda #$82
	sta hposp1
	sta pcolr0
	sta pcolr1
	sta pmbase
	lda #$7d
	sta hposp2
	lda #$7a
	sta hposp0
	sta sdmctl
	sta gractl

	; draw diagonal line #2
	sta opcodc2	; illegal opcode "npo" ($7a)
	sta opcodc3	; illegal opcode "npo" ($7a)
	jsr draw

	stx color2

	; draw diagonal line #3
	sta opcodc1	; illegal opcode "dop #n" ($80)
	jsr draw

	; for diagonal lines preview; not needed for normal operation
.if .def debug
	lda #<dlist+4
	sta memdbg1
	lda #>dlist
	sta memdbg1+1
	lda #<vidptr
	sta memdbg2
	lda #>vidptr+offset
	sta memdbg2+1
	ldx #vertlin
	ldy #$00
loopd1	lda memdbg2
	sta (memdbg1),y
	inc memdbg1
	bne skipd1
	inc memdbg1+1
skipd1	lda memdbg2+1
	sta (memdbg1),y
	lda memdbg2
	clc
	adc #$40
	sta memdbg2
	bne skipd2
	inc memdbg2+1
skipd2	inc memdbg1
	bne skipd3
	inc memdbg1+1
skipd3	inc memdbg1
	bne skipd4
	inc memdbg1+1
skipd4	dex
	bne loopd1
	lda #$01
	sta colpf1
	jmp *
.endif

	; set VBI routine
	lda #$07
	ldy <vbirout
	ldx >vbirout
	jsr setvbv

	; main loop
anim	sta wsync
	lda vcount	; gray rainbow
	asl
	sta colpf1
	bvc anim	; 1 byte less than "jmp anim"

	; vertical blank interrupt routine
vbirout	lda #<dlist+4
	sta memdl2
	lda #>dlist
	sta memdl2+1
	ldx #vertlin
loopb1	ldy #$00
	lda (memdl2),y
	;clc		; not needed in practice
	adc #$40
	sta (memdl2),y
	bne skipb1
	iny
	lda (memdl2),y
	adc #$00	; +1, carry flag is set
	bpl skipb2
	lda #>vidptr
skipb2	sta (memdl2),y
skipb1	inc memdl2
	bne skipb3
	inc memdl2+1
skipb3	inc memdl2
	bne skipb4
	inc memdl2+1
skipb4	inc memdl2
skipb5	dex
	bne loopb1
	sta pcolr2
	jmp xitvbv

	; draw a diagonal line
draw	;lda <vidptr	; not needed
	;sta memvp1
	lda >vidptr
	sta memvp1+1
	lda #%10000000
	;ldx #$00	; not needed
	ldy #$04
loopc1	lsr
opcodc1	lsr
opcodc2	lsr
opcodc3	lsr
	bcc skipc2
	iny
	cpy #$24
	bne skipc1
	ldy #$04
skipc1	lda #%10000000
skipc2	pha
	sta (memvp1),y
	lda memvp1
	clc
	adc #$40
	sta memvp1
	bne skipc3
	inc memvp1+1
skipc3	pla
	dex
	bne loopc1
	rts

	org $8476
ufoleft	.byte $03, $04, $08, $08, $3c, $7f, $df, $fb, $7f, $1f

	org $8577
uforght	.byte $80, $40, $40, $f0, $f8, $ec, $7c, $f8, $e0

	org $8683
jet	.byte $18, $00, $3c, $00, $7e
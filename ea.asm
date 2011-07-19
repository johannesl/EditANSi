;/*
;
;  EditANSi - The Innovative ANSi Editor
;
;  Copyright (c) 2004 Johannes Lundberg, released to the public domain.
;
;  Coded using the 8086 instruction set.
;  Assemble with Netwide Assembler (NASM).
;
;*/

%define DEBUG

[org 0x100]
[cpu 8086]

;*****************************************************
;*
;*  Initialization
;*
;*****************************************************
init:
        ; MODE3 (80x25 EGA COLORS)
        mov     ax, 0x03
        int     0x10

        ; Set cursor type
        mov     ax, 0x0100
        mov     cx, 0x0007      ; scanline 0x00->0x07
        int     0x10

        ; Set keyboard repeat rate
        mov     ax, 0x0305
        mov     bx, 0x0000
        int     0x16

        ; Display bar
        les     bx, [vidmem]
        mov     byte [es:bx], '*';
        mov     byte [es:bx+2], '*';

;*****************************************************
;*
;*  Main loop
;*
;*****************************************************
premain:
        ; Set cursor position
        mov     ah, 0x02
        mov     bh, 0x0
        mov     dh, [ypos]
        mov     dl, [xpos]
        int     0x10

main:
        ; BIOS readkey
	mov	ax, 0x0000
	int	0x16

        ; CTRL keys
        mov     bx, ax
        mov     ah, 0x02
        int     0x16
        mov     ah, bh
        and     al, 0x02

        cmp     ax, 0x4802      ; UP
        je      jt_sup
        cmp     ax, 0x5002      ; DOWN
        je      jt_sdown
        cmp     ax, 0x4B02      ; LEFT
        je      jt_sleft
        cmp     ax, 0x4D02      ; RIGHT
        je      jt_sright
        mov     ax, bx

        ; F1-F10
        mov     bl, ah
        mov     bh, al
        sub     bx, 0x003B
        cmp     bx, 0x0A
        jb      jt_fn

        ; ALT1-ALT0
;        mov     bl, ah
;        mov     bh, al
;        sub     bx, 0x0078
        sub     bx, 0x003D          ; 0x78-0x3B
        cmp     bx, 0x0A
        jb      jt_altn

        cmp     ax, 0x1600      ; ALT-U
        je      jt_altu
        cmp     ax, 0x2C00      ; ALT-Z
        je      jt_altz

        cmp     ax, 0x1F00      ; ALT-S
        je      jt_alts
        cmp     ax, 0x2600      ; ALT-L
        je      jt_altl

        cmp     ax, 0x4800      ; UP
        je      jt_up
        cmp     ax, 0x5000      ; DOWN
        je      jt_down
        cmp     ax, 0x4B00      ; LEFT
        je      jt_left
        cmp     ax, 0x4D00      ; RIGHT
        je      jt_right

        cmp     ax, 0x011B      ; ESC
        je      jt_esc

        ; ASCII characters

        cmp     al, 0x00
        jne     k_ascii

        ; Loop
        jmp     main

;; JUMP TABLE
jt_fn:          jmp     k_fn
jt_esc:         jmp     k_esc
jt_altn:        jmp     k_altn
jt_up:          jmp     k_up
jt_down:        jmp     k_down
jt_left:        jmp     k_left
jt_right:       jmp     k_right
jt_sup:         jmp     k_sup
jt_sdown:       jmp     k_sdown
jt_sleft:       jmp     k_sleft
jt_sright:      jmp     k_sright
jt_altu:        jmp     k_altu
jt_altz:        jmp     k_altz
jt_alts:        jmp     k_alts
jt_altl:        jmp     k_altl

loadpos:
        mov     dl, [ypos]
        mov     dh, 0
        mov     ax, 80
        mul     dx

        mov     dl, [xpos]
        mov     dh, 0
        add     ax, dx

        shl     ax, 1

        les     bx, [vidmem]
        add     bx, ax
        ret

;********************************************
;*
;*  Keyboard actions
;*
;********************************************

k_fn:
        add     bx, set0
        add     bx, [set]
        mov     si, bx
        mov     al, [ds:si]

k_ascii:
        mov     cl, al
%if 0
        mov     dl, [ypos]
        mov     dh, 0
        mov     ax, 80
        mul     dx

        mov     dl, [xpos]
        mov     dh, 0
        add     ax, dx

        shl     ax, 1

        les     bx, [vidmem]
        add     bx, ax
%endif
        call    loadpos
        mov     byte [es:bx], cl
        mov     cl, [color]
        mov     byte [es:bx+1], cl

        ; Move cursor right
        jmp     k_right

k_altn:
        mov     al, bl
        mov     dl, 10
        mul     dl
        mov     [set], al
        jmp     main

k_up:
        mov     al, [ypos]
        cmp     al, 1
        je      main

        dec     byte [ypos]
        jmp     premain

k_down:
        mov     al, [ypos]
        cmp     al, 24
        je      main

        inc     byte [ypos]
        jmp     premain

k_left:
        mov     al, [xpos]
        cmp     al, 0
        je      main

        dec     byte [xpos]
        jmp     premain

k_right:
        mov     al, [xpos]
        cmp     al, 79
        je      main

        inc     byte [xpos]
        jmp     premain

k_sup:
        mov     al, [color]
        mov     ah, al
        dec     al
        and     al, 0x0F
        and     ah, 0xF0
        or      al, ah
        mov     byte [color], al
        jmp     p_colors

k_sdown:
        mov     al, [color]
        mov     ah, al
        inc     al
        and     al, 0x0F
        and     ah, 0xF0
        or      al, ah
        mov     [color], al
        jmp     p_colors

k_sleft:
        mov     al, [color]
        mov     ah, al
        sub     ah, 16
        and     al, 0x0F
        and     ah, 0x70        ; No blink
        or      al, ah
        mov     byte [color], al
        jmp     p_colors

k_sright:
        mov     al, [color]
        mov     ah, al
        add     ah, 16
        and     al, 0x0F
        and     ah, 0x70        ; No blink
        or      al, ah
        mov     [color], al
        jmp     p_colors

k_altz:
        call    loadpos
        mov     al, [color]
        mov     [es:bx+1], al
        jmp     k_right

k_altu:
        call    loadpos
        mov     al, [es:bx+1]
        mov     [color], al

p_colors:
        les     bx, [vidmem]
        mov     al, [color]
        mov     byte [es:bx+1], al
        mov     byte [es:bx+3], al
        jmp     main

k_alts:

%if 1
        mov     ah, 0x3C        ; Open file
        mov     cx, 0x0000
        mov     al, 0x01        ; Only write
        mov     dx, filename
        int     0x21
%endif

%if 0
        mov     ax, filename
        mov     si, ax
        mov     ax, 0x6C00      ; Open file
        mov     bx, 0x01        ; Only write
        mov     dx, 0x21        ; Create/truncate
        int     0x21
%endif

        jc      k_fn

        push    ds

        mov     dx, 0xB800      ; (FIXME: This should use vidmem)
        push    dx              ; Set DS to point to video-segment
        pop     ds
        mov     dx, 160         ; Skip status row (80*2)

        mov     bx, ax
        mov     ah, 0x40        ; Write to file
        mov     cx, 3840        ; 80*24*2
        int     0x21

        pop     ds

;        mov     bx, ax
        mov     ah, 0x3E
        int     0x21

        jmp     main

k_altl:
        mov     ah, 0x3D        ; Open file
;        mov     cx, 0x0000
        mov     al, 0x00        ; Only read
        mov     dx, filename
        int     0x21

        push    ds

        mov     dx, 0xB800      ; (FIXME: This should use vidmem)
        push    dx              ; Set DS to point to video-segment
        pop     ds
        mov     dx, 160         ; Skip status row (80*2)

        mov     bx, ax
        mov     ah, 0x3F        ; Read from file
        mov     cx, 3840        ; 80*24*2
        int     0x21

        pop     ds

;        mov     bx, ax
        mov     ah, 0x3E
        int     0x21

        jmp     main

k_esc:
        ; Verify user wants to quit
        mov     ax, 0x0000
        int     0x16

        ; 'y' or 'Y'
        and     ax, 0xFFDF
        cmp     ax, 0x1559
        jne     main

        ; Restore cursor type
        mov     ax, 0x0100
        mov     cx, 0x0607
        int     0x10

        ; Clear screen
        mov     ax, 0x03
        int     0x10

        ; Magic
;        ret
        mov     ax, 0x4C00
        int     0x21

%ifdef DEBUG
;**************************
;* Display binary sequence
;* AX = 16-bit integer
;**************************
binprint:
        push    ax
        mov     dx, ax
        mov     cx, 16
binloop:
        mov     al, 0
        shl     dx, 1
        jnc     zero
        mov     al, 1
zero:
        add     al, 0x30
	mov	ah, 0x0E
	mov	bx, 0x0017
	int	0x10

        loop    binloop

        mov     al, ' '
	mov	ah, 0x0E
	mov	bx, 0x0017
	int	0x10
        pop     ax
        ret


;************************
;* Print a 16-bit in hex.
;* AX = integer to print
;************************
hexprint:
        push    ax
	mov	dx, ax
	mov	cx, 0

	mov	ax, 0x000D	;<CR>
	push	ax
	mov	ax, 0x000A	;<LF>
	push	ax
hexloop:
	mov	ax, dx
	and	al, 0x0F

	cmp	al, 0x0A
	jb	hoho
	add	al, 0x07
hoho:
	add	al, 0x30

	push	ax

        shr     dx, 1
        shr     dx, 1
        shr     dx, 1
        shr     dx, 1

	inc	cx
	cmp	cx, 4
	jne	hexloop

	add	cx, 2	; <CR><LF>

hexloop2:
	pop	ax
	mov	ah, 0x0E
	mov	bx, 0x0017
	int	0x10

	dec	cx
	cmp	cx, 0
	jne	hexloop2
        pop     ax
	ret
%endif

;********************************************************
;*
;*  Variables
;*
;********************************************************

xpos    db      0
ypos    db      1
color   db      0x07
set     dw      0x0000
vidmem  dd      0xB8000000
;vidmem  dd      0xA0000000
set0    db      'Ú¿ÀÙÄ³Ã´ÁÂ'    ; lines
        db      'É»È¼ÍºÌ¹ÊË'
        db      'Õ¸Ô¾Í³ÆµÏÑ'
        db      'Ö·Ó½ÄºÇ¶ÐÒ'
        db      'ÅÎØ×èé›œ™ï'
        db      '°±²ÛßÜÝÞþú'    ; blocks
filename db     'EASAVE22.BIN', 0

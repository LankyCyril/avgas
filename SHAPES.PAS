{$A-,B-,D-,E-,F-,G+,I-,L-,N-,O-,P-,Q-,R-,S-,T-,V-,X+,Y-}
UNIT SHAPES {
    Defines functions that draw shapes (lines, rectangles, etc).
    Introduces a mask, which must be set to 255 first (`resetmask`):
      * every drawing function in this unit will only modify
        pixels where mask is 255;
      * where mask is 0, the screen remains intact.
    Function `maskblock()` can be used to modify parts of the mask:
      * maskblock([coords], true) masks the block with [coords];
      * maskblock([coords], false) frees up the block.
    Calling `resetmask` again clears mask and allows all pixels to be
    written to.
    Currently compiles under 16-bit Turbo Pascal to just 1376 bytes!
};

INTERFACE

procedure resetmask {
    resets mask; must be called, otherwise mask is garbage
};
function maskblock(x1, y1, x2, y2: word; state: boolean): boolean {
    adds a rectangular area to mask
};
function mputpixel(x, y: word; color: byte): boolean {
    sets color of pixel at `x` and `y` to `color`, dodging mask
};
function line(x1, y1, x2, y2: word; color: byte): boolean {
    draws a line from point (x1, y1) to point (x2, y2) with `color`
};
function block(x1, y1, x2, y2: word; color: byte): boolean {
    draws a filled rectangle of `color` from point (x1, y1) to point (x2, y2)
};

IMPLEMENTATION

uses graphics;

type ScreenMask = array[0..63999] of byte;
var screen_mask: ^ScreenMask; {this is big, have to store in extended mem}

procedure resetmask {
    Resets mask; must be called, otherwise mask is garbage
};
begin
    new(screen_mask); {make pointer available for inside assembly}
    asm {fillchar(screen_mask^, 64000, 0), but 16 bytes leaner}
        push es
        cld
        les  di, screen_mask
        mov  cx, 32000
        mov  ax, 0FFFFh
        @loop_resetmask:
            stosw
            sub   cx, 1
            jnz   @loop_resetmask
        pop  es
    end;
end;

function maskblock(x1, y1, x2, y2: word; state: boolean): boolean; assembler {
    Adds a rectangular area to mask;
    returns false if area fully out of bounds or has negative dimensions;
    returns true otherwise.
};
asm
    mov cx, x1
    cmp cx, getmaxx          {if x1 > getmaxx, mask is null}
        ja @fail_maskblock

    mov dx, x2
    cmp dx, getmaxx          {if x2 > getmaxx, need to cap it}
        jna @valid_x2
        mov dx, getmaxx
    @valid_x2:
    cmp cx, dx               {if x1 > x2, mask is null}
        ja @fail_maskblock

    mov ax, y1
    cmp ax, getmaxy          {if y1 > getmaxy, mask is null}
        ja @fail_maskblock
    mov bx, y2
    cmp bx, getmaxy          {if y2 > getmaxy, need to cap it}
        jna @valid_y2
        mov bx, getmaxy
    @valid_y2:
    cmp ax, bx               {if y1 > y2, mask is null}
        ja @fail_maskblock

    sub dx, cx               {CX = mask x1, DX = mask width}
    add dx, 1                {width is inclusive!}
    sub bx, ax               {AX = mask y1, BX = mask height}
    add bx, 1                {height is inclusive!}

    push es
    les  di, screen_mask     {point [ES:DI] to screen_mask^[0]}
    shl  ax, 6
    add  di, ax              {point [ES:DI] to screen_mask^[y1 * 64]}
    shl  ax, 2
    add  di, ax              {point [ES:DI] to screen_mask^[y1 * 320]}
    add  di, cx              {point [ES:DI] to screen_mask^[y1 * 320 + x1]}

    mov ah, 255
    add ah, state            {AH = 0 if state is true, and vice versa}

    @loop_maskblock_y:
        push dx
        @loop_maskblock_x:
            mov  [es:di], ah
            add  di, 1       {move pointer right along mask}
            sub  dx, 1       {until width of current horizontal line}
            jnz  @loop_maskblock_x
        pop  dx              {rescue width for next line}
        sub  di, dx          {move pointer left along mask (carriage return)}
        add  di, 320         {move pointer down along mask (new line)}
        sub  bx, 1           {until height of current block}
        jnz  @loop_maskblock_y

    pop es
    mov al, 1                {return true}
    jmp @finish_maskblock

    @fail_maskblock:
        mov al, 0            {return false}
    @finish_maskblock:
end;

function mputpixel(x, y: word; color: byte): boolean; assembler {
    Sets color of pixel at `x` and `y` to `color`, dodging mask;
    returns boolean value of success
};
asm
    mov ax, x
    cmp ax, getmaxx
        ja @fail_mputpixel
    mov bx, y
    cmp bx, getmaxy
        ja @fail_mputpixel

    shl bx, 6
    mov di, bx
    shl di, 2
    add di, bx
    add di, ax

    push ds
    lds  si, screen_mask
    add  si, di
    mov  ah, [ds:si]
    pop  ds
    cmp  ah, 0
        je @fail_mputpixel

    push es
    mov  ax, 0A000h
    mov  es, ax
    mov  bl, color
    mov  [es:di], bl
    pop  es

    mov al, 1
    jmp @finish_mputpixel

    @fail_mputpixel:
        mov al, 0
    @finish_mputpixel:
end;

function line(x1, y1, x2, y2: word; color: byte): boolean; assembler {
    Draws a line from point (x1, y1) to point (x2, y2) with `color`;
    returns false if completely out of bounds, true otherwise.
};
asm
    push ds
    push es

    mov ax, x1
    mov bx, x2
    cmp ax, bx
        jna @ltr_line
    xchg ax, bx
    @ltr_line:

    mov cx, y1
    mov dx, y2
    cmp cx, dx
        jna @ttb_line
    xchg cx, dx
    @ttb_line:

    cmp ax, getmaxx
        ja @fail_line
    cmp cx, getmaxy
        ja @fail_line

    cmp bx, getmaxx
        jna @rtl_inbounds_line
    mov bx, getmaxx
    @rtl_inbounds_line:

    cmp dx, getmaxy
        jna @ttb_inbounds_line
    mov dx, getmaxy
    @ttb_inbounds_line:

    cmp ax, bx
        je @line_vertical
    cmp cx, dx
        je @line_horizontal

    @line_diagonal:
        jmp @fail_line

    @line_vertical:
        sub dx, cx  {CX = y1, DX = height, AX = x}
        add dx, 1   {height is inclusive!}
        shl cx, 6
        mov di, cx
        shl di, 2
        add di, cx
        add di, ax  {point DI to offset of line's first pixel}
        shl dx, 6
        mov ax, dx
        shl dx, 2
        add dx, ax
        add dx, di  {DX = offset of line's last pixel}
        sub di, 320 {move back up one step, for easier looping conditions}

        lds si, screen_mask
        add si, di  {point [DS:SI] to 320b before line's 1st pixel in mask}

        mov ax, 0A000h
        mov es, ax  {point [ES:DI] to 320b before line's 1st pixel on screen}

        mov al, 1   {prepare to return true}
        mov bl, color

        @loop_vline:
            add di, 320     {advance screen, one line down}
            add si, 320     {advance mask, one line down}
            cmp dx, si      {finish if arrived at offset of last pixel}
                je @finish_line
            mov bh, [ds:si] {check mask at offset}
            cmp bh, 0       {skip pixel if mask at offset is zero}
                je @loop_vline
            mov [es:di], bl {put pixel otherwise}
            jmp @loop_vline

    @line_horizontal:
        sub bx, ax {AX = x1, BX = width, CX = y}
        add bx, 1  {width is inclusive!}
        shl cx, 6
        mov di, cx
        shl di, 2
        add di, cx
        add di, ax {point DI to offset of line's first pixel}
        add bx, di {BX = offset of line's last pixel}
        sub di, 1  {move back one step, for easier checks in @loop_hline}

        lds si, screen_mask
        add si, di {point [DS:SI] to 1b before line's 1st pixel in mask}

        mov ax, 0A000h
        mov es, ax {point [ES:DI] to 1b before line's 1st pixel on screen}

        mov al, 1  {prepare to return true}
        mov dl, color

        @loop_hline:
            inc di          {advance screen}
            inc si          {advance mask}
            cmp bx, si      {finish if arrived at offset of last pixel}
                je @finish_line
            mov dh, [ds:si] {check mask at offset}
            cmp dh, 0       {skip pixel if mask at offset is zero}
                je @loop_hline
            mov [es:di], dl {put pixel otherwise}
            jmp @loop_hline

    @fail_line:
        mov al, 0  {return false}
    @finish_line:
        pop es
        pop ds
end;

function block(x1, y1, x2, y2: word; color: byte): boolean; assembler {
    Draws a filled rectangle of `color` from point (x1, y1) to point (x2, y2);
    returns false if has negative dimensions or completely out of bounds;
    otherwise, returns true.
};
asm
    push ds
    push es

    mov ax, x1
    mov bx, x2
    cmp ax, bx
        jna @ltr_block
    xchg ax, bx
    @ltr_block:

    mov cx, y1
    mov dx, y2
    cmp cx, dx
        jna @ttb_block
    xchg cx, dx
    @ttb_block:

    cmp ax, getmaxx
        ja @fail_block
    cmp cx, getmaxy
        ja @fail_block

    cmp bx, getmaxx
        jna @rtl_inbounds_block
    mov bx, getmaxx
    @rtl_inbounds_block:

    cmp dx, getmaxy
        jna @ttb_inbounds_block
    mov dx, getmaxy
    @ttb_inbounds_block:

    sub dx, cx  {CX = y1, DX = height}
    add dx, 1   {height is inclusive!}

    shl cx, 6
    mov di, cx
    shl di, 2
    add di, cx
    add di, ax  {point DI to offset of line's first pixel}

    sub bx, ax  {BX = width}
    add bx, 2   {width is inclusive! + extra byte for retracing in loop}
    dec di      {point DI to 1b before offset of line's 1st pixel}

    lds si, screen_mask
    add si, di  {point [DS:SI] to 1b before line's first pixel in mask}

    mov ax, 0A000h
    mov es, ax  {point [ES:DI] to 1b before line's first pixel on screen}

    mov al, color

    @loop_block_y:
        push bx
        @loop_block_x:
            inc si
            inc di
            dec bx
            cmp bx, 0
                je  @endloop_block_x
            mov ah, [ds:si]
            cmp ah, 0
                je @loop_block_x
            mov [es:di], al
            cmp bx, 0
            ja  @loop_block_x
        @endloop_block_x:
        pop bx
        add si, 320
        sub si, bx
        add di, 320
        sub di, bx
        dec dx
        cmp dx, 0
        ja @loop_block_y

    mov al, 1      {prepare to return true}
    jmp @finish_block

    @fail_block:
        mov al, 0  {return false}
    @finish_block:
        pop es
        pop ds
end;

end.

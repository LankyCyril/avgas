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
    Currently compiles under 16-bit Turbo Pascal to just 1424 bytes!
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
function hline(x1, x2, y: word; color: byte): boolean {
    draws a horizontal line from point (x1, y) to point (x2, y) with `color`
};
function vline(x, y1, y2: word; color: byte): boolean {
    draws a vertical line from point (x, y1) to point (x, y2) with `color`
};
function block(x1, y1, x2, y2: word; color: byte): boolean {
    draws a filled rectangle of `color` from point (x1, y1) to point (x2, y2)
};

IMPLEMENTATION

uses graphics;

type ScreenMask = array[0..63999] of byte;
var screen_mask: ^ScreenMask;

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
    mov al,  1               {return true}
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

function hline(x1, x2, y: word; color: byte): boolean; assembler {
    Draws a horizontal line from point (x1, y) to point (x2, y) with `color`;
    returns false if completely out of bounds, true otherwise.
};
asm
    push ds
    push es

    mov dx, y
    cmp dx, getmaxy
        ja @fail_hline

    mov  bx, x1
    mov  cx, x2
    cmp  bx, cx
        jna @forward_hline
    xchg bx, cx

    @forward_hline:
        cmp bx, getmaxx
            ja @fail_hline
        cmp cx, getmaxx
            jna @valid_hline
        mov cx, getmaxx

    @valid_hline:
        sub cx, bx  {BX = x1, CX = width, DX = y}
        add cx, 1   {width is inclusive!}
        shl dx, 6
        mov di, dx
        shl di, 2
        add di, dx
        add di, bx  {point DI to offset of line's first pixel}
        add cx, di  {CX = offset of line's last pixel}
        sub di, 1   {move back one step, for easier checks in @loop_hline}

        lds si, screen_mask
        add si, di {point [DS:SI] to 1b before line's 1st pixel in mask}

        mov ax, 0A000h
        mov es, ax {point [ES:DI] to 1b before line's 1st pixel on screen}

        mov al, 1
        @loop_hline:
            inc di
            inc si
            cmp cx, si
                je @finish_hline
            mov ah, [ds:si]
            cmp ah, 0
                je @loop_hline
            mov ah, color
            mov [es:di], ah
            jmp @loop_hline

    @fail_hline:
        mov al, 0
    @finish_hline:
        pop es
        pop ds
end;

function vline(x, y1, y2: word; color: byte): boolean {
    Draws a vertical line from point (x, y1) to point (x, y2) with `color`;
    returns false if y1 > y2 or if completely out of bounds, true otherwise.
};
var length, yd, startmem: word;
begin
    vline := true;
    if (y1 > y2) or (x > getmaxx) or (y1 > getmaxy) then
        vline := false
    else begin
        if y2 > getmaxy then
            length := getmaxy - y1 + 1
        else
            length := y2 - y1 + 1;
        startmem := y1 shl 8 + y1 shl 6 + x;
        for yd := 0 to length do
            mem[$A000: startmem + yd shl 8 + yd shl 6] := color;
    end;
end;

function block(x1, y1, x2, y2: word; color: byte): boolean {
    Draws a filled rectangle of `color` from point (x1, y1) to point (x2, y2);
    returns false if has negative dimensions or completely out of bounds;
    otherwise, returns true.
};
var y: word;
begin
    block := true;
    if (x1 > x2) or (y1 > y2) or (x1 > getmaxx) or (y1 > getmaxy) then
        block := false
    else for y := y1 to y2 do
        hline(x1, x2, y, color);
end;

end.

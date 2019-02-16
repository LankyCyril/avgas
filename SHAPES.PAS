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
};

INTERFACE

procedure resetmask {
    resets mask; must be called, otherwise mask is garbage
};
function maskblock(x1, y1, x2, y2: word; state: boolean): boolean {
    adds a rectangular area to mask
};
function mputpixel(x, y: word; color: byte): boolean {
    sets color of pixel at `x` and `y` to `color`, dodging mask; SLOW!
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
    asm
        push es
        cld
        les  di, screen_mask
        mov  cx, 32000
        @loop_resetmask: {basically fillchar, but 16 bytes leaner}
            mov   ax, 0FFFFh
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
    mov  al, 0               {assume return false unless proven successful}

    mov  cx, x1
    cmp  cx, getmaxx         {if x1 > getmaxx, mask is null}
        ja @fail_maskblock
    mov  dx, x2
    cmp  dx, getmaxx         {if x2 > getmaxx, need to cap it}
        ja @set_dx_to_getmaxx
        @dx_is_getmaxx:
    cmp  cx, dx              {if x1 > x2, mask is null}
        ja @fail_maskblock

    mov  ax, y1
    cmp  ax, getmaxy         {if y1 > getmaxy, mask is null}
        ja @fail_maskblock
    mov  bx, y2
    cmp  bx, getmaxy         {if y2 > getmaxy, need to cap it}
        ja @set_bx_to_getmaxy
        @bx_is_getmaxy:
    cmp  ax, bx              {if y1 > y2, mask is null}
        ja @fail_maskblock

    sub  dx, cx              {CX = mask x1, DX = mask width}
    add  dx, 1               {width is inclusive!}
    sub  bx, ax              {AX = mask y1, BX = mask height}
    add  bx, 1               {height is inclusive!}

    push es
    les  di, screen_mask     {point [ES:DI] to screen_mask^[0]}
    push ax
    shl  ax, 8
    add  di, ax              {point [ES:DI] to screen_mask^[y1 * 240]}
    pop  ax
    shl  ax, 6
    add  di, ax              {point [ES:DI] to screen_mask^[y1 * 320]}
    add  di, cx              {point [ES:DI] to screen_mask^[y1 * 320 + x1]}

    mov  ah, 255
    add  ah, state
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

    pop  es
    mov  al, 255             {return true; AL cannot be 255 otherwise,}
    jmp @finish_maskblock    {because 255 > getmaxy and would've been capped}

    @set_dx_to_getmaxx:
        cmp  al, 255         {if function already successful, return}
            je @finish_maskblock
        mov  dx, getmaxx
        jmp  @dx_is_getmaxx

    @set_bx_to_getmaxy:
        cmp  al, 255         {if function already successful, return}
            je @finish_maskblock
        mov  bx, getmaxy
        jmp  @bx_is_getmaxy

    @fail_maskblock:
        mov al, 0            {return false}
    @finish_maskblock:
end;

function mputpixel(x, y: word; color: byte): boolean {
    Sets color of pixel at `x` and `y` to `color`, dodging mask; SLOW!;
    returns boolean value of success
};
begin
    mputpixel := false;
    if (x <= getmaxx) and (y <= getmaxy) then begin
        x := y shl 8 + y shl 6 + x; {320 * y + x}
        if screen_mask^[x] <> 0 then begin
           mem[$A000:x] := color;
           mputpixel := true;
        end;
    end;
end;

function hline(x1, x2, y: word; color: byte): boolean {
    Draws a horizontal line from point (x1, y) to point (x2, y) with `color`;
    returns false if x1 > x2 or if completely out of bounds, true otherwise.
};
var length: word;
begin
    hline := true;
    if (x1 > x2) or (x1 > getmaxx) or (y > getmaxy) then
        hline := false
    else if x1 <= getmaxx then begin
        if x2 > getmaxx then
            length := getmaxx - x1 + 1
        else
            length := x2 - x1 + 1;
        fillchar(mem[$A000: y shl 8 + y shl 6 + x1], length, color);
    end
    else
        mem[$A000: y shl 8 + y shl 6 + x1] := color;
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

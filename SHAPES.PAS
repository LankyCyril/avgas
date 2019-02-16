UNIT SHAPES;

INTERFACE

function hline(x1, x2, y: word; color: byte): boolean {
    draws a horizontal line from point (x1, y) to point (x2, y) with `color`
};
function vline(x, y1, y2: word; color: byte): boolean {
    draws a vertical line from point (x, y1) to point (x, y2) with `color`
};
function block(x1, y1, x2, y2: word; color: byte): boolean {
    draws a filled rectangle of `color` from point (x1, y1) to point (x2, y2)
};
procedure resetmask {
    resets mask
};
procedure maskblock(x1, y1, x2, y2: word) {
    adds a rectangular area to mask
};

type ScreenMask = array[0..63999] of byte;
var screen_mask: ^ScreenMask;

IMPLEMENTATION

uses graphics;

function hline(x1, x2, y: word; color: byte): boolean {
    Draws a horizontal line from point (x1, y) to point (x2, y) with `color`;
    truncates line appropriately if outside of screen bounds;
    if x1 > x2, or if line completely out of bounds, returns false;
    otherwise returns true.
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
    returns false y1 > y2 or if completely out of bounds, true otherwise.
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

procedure resetmask;
begin
    new(screen_mask);
    asm
        push es
        cld
        les  di, screen_mask
        mov  cx, 32000
        @loop_resetmask:
            mov   ax, 0FFFFh
            stosw
            sub   cx, 1
            jnz   @loop_resetmask
        pop  es
    end;
end;

procedure maskblock(x1, y1, x2, y2: word); assembler {
    Adds a rectangular area to mask
};
asm
    mov  ax, x1
    cmp  ax, getmaxx         {if x1 > getmaxx, mask is null}
        ja @nomask
    mov  bx, x2
    cmp  ax, bx              {if x1 > x2, mask is null}
        ja @nomask

    mov  cx, y1
    cmp  cx, getmaxy         {if y1 > getmaxy, mask is null}
        ja @nomask
    mov  dx, y2
    cmp  cx, dx              {if y1 > y2, mask is null}
        ja @nomask

    sub  bx, ax              {AX = mask x1, BX = mask width}
    sub  dx, cx              {CX = mask y1, DX = mask height}

    push es
    les  di, screen_mask     {point [ES:DI] to screen_mask^[0]}
    push cx
    shl  cx, 8
    add  di, cx              {point [ES:DI] to screen_mask^[y1 * 240]}
    pop  cx
    shl  cx, 6
    add  di, cx              {point [ES:DI] to screen_mask^[y1 * 320]}
    add  di, ax              {point [ES:DI] to screen_mask^[y1 * 320 + x1]}

    @loop_maskblock_y:
        push bx
        @loop_maskblock_x:
            mov  ax, 0
            mov  [es:di], ax
            add  di, 1       {move pointer right along mask}
            sub  bx, 1       {until width of current horizontal line}
            jnz  @loop_maskblock_x
        pop  bx              {rescure width for next line}
        add  di, 320         {move pointer down along mask}
        sub  dx, 1           {until height of current block}
        jnz  @loop_maskblock_y

    pop  es
    @nomask:
end;

end.
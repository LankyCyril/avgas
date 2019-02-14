UNIT PALETTES;

INTERFACE

type Palette216 = array[0..647] of byte;

procedure showpalette {
    displays the current 216 color palette in a grid
};
procedure fade(smoothing: byte) {
    darkens and washes out VGA palette
};
procedure setpalette(const palette: Palette216) {
    sets the 216 palette to values stored in `palette`
};

const OUTRUN: Palette216 = (
       0,  0,  0,  0, 48, 49,  0, 59, 59,  0, 63, 61,  0, 63, 63,  1, 35, 44,
       1, 48, 51,  1, 59, 60,  1, 63, 63,  2,  2,  7,  2,  8, 29,  2, 10, 29,
       2, 11, 30,  2, 14, 39,  3,  0,  6,  3, 11, 38,  3, 14, 31,  3, 20, 38,
       4,  3, 32,  4,  8, 30,  4,  8, 39,  4, 11, 32,  4, 14, 36,  4, 16, 38,
       4, 17, 39,  4, 17, 43,  4, 21, 48,  4, 27, 46,  4, 61, 62,  5,  0,  8,
       5,  1,  8,  5,  2,  7,  5,  2,  8,  5,  2,  9,  5,  2, 10,  5,  4,  8,
       5,  5, 17,  5,  9, 21,  5, 14, 39,  5, 14, 42,  5, 17, 50,  5, 19, 47,
       6,  0,  8,  6,  0, 10,  6,  2,  7,  6,  2,  8,  6,  2,  9,  6,  2, 10,
       6,  3, 12,  6,  3, 18,  6,  6, 18,  6,  7, 20,  6,  8, 30,  6, 11, 37,
       6, 14, 50,  7,  0,  9,  7,  2,  8,  7,  2,  9,  7,  2, 10,  7,  2, 11,
       7,  3,  9,  7,  7, 53,  7,  8, 42,  7, 11, 31,  7, 11, 50,  8,  0, 10,
       8,  0, 11,  8,  2,  9,  8,  2, 10,  8,  2, 11,  8,  2, 12,  8,  3, 10,
       8,  3, 11,  8,  3, 12,  8,  3, 13,  8,  4, 14,  8, 15, 49,  8, 47, 53,
       9,  2, 10,  9,  2, 11,  9,  2, 12,  9,  2, 13,  9,  3, 11,  9,  3, 12,
       9,  3, 13,  9,  4, 11,  9,  4, 12,  9,  4, 13,  9,  4, 14,  9,  4, 15,
       9,  5, 15,  9,  5, 16,  9,  5, 17,  9, 20, 49,  9, 34, 50, 10,  0, 12,
      10,  2, 12, 10,  3, 12, 10,  3, 13, 10,  3, 14, 10,  4, 14, 10,  4, 15,
      11,  3, 14, 11,  3, 15, 11,  4, 15, 11,  4, 16, 11,  5, 16, 11,  5, 17,
      11,  5, 18, 11,  6, 17, 11,  6, 19, 11,  7, 20, 11,  8, 23, 11,  9, 19,
      12,  1, 13, 12,  4, 15, 12,  4, 16, 12,  4, 17, 12, 14, 29, 13,  3, 16,
      13,  4, 16, 13,  4, 17, 13,  5, 17, 13,  6, 19, 13, 15, 49, 14,  1, 14,
      14,  1, 15, 14,  4, 17, 14,  5, 18, 14,  6, 20, 14, 19, 32, 15,  2, 17,
      15,  3, 18, 15,  5, 18, 15,  7, 21, 15,  7, 22, 15,  8, 23, 15,  9, 15,
      15,  9, 21, 15,  9, 24, 15, 10, 27, 16,  1, 16, 16,  4, 19, 16,  6, 19,
      16,  6, 20, 17,  2, 17, 17,  3, 18, 18,  0, 16, 18,  2, 18, 18,  2, 19,
      18,  3, 19, 18,  3, 20, 18, 21, 48, 19,  0, 19, 19,  2, 20, 19,  3, 20,
      19,  4, 21, 19,  5, 20, 19,  7, 20, 20,  3, 21, 20,  7, 22, 20,  7, 23,
      20,  9, 20, 20,  9, 26, 20, 26, 44, 21,  3, 21, 21,  8, 24, 21, 14, 26,
      22,  0, 20, 22,  2, 21, 22,  3, 22, 22, 19, 28, 23,  1, 22, 23,  1, 23,
      23,  4, 24, 25,  3, 24, 25,  8, 24, 26,  1, 24, 26,  3, 25, 26,  6, 26,
      26, 61, 59, 27,  4, 26, 27,  8, 29, 28,  2, 26, 30,  2, 29, 30, 15, 26,
      31, 21, 26, 31, 21, 43, 32, 15, 37, 33,  7, 32, 33, 10, 31, 34,  1, 32,
      36, 29, 50, 37, 29, 23, 42,  9, 40, 42, 37, 44, 44, 21, 36, 45,  2, 43,
      45, 15, 36, 55, 28, 15, 56, 30, 48, 56, 47, 43, 57,  9, 50, 57, 16, 31,
      57, 22, 25, 58, 38, 45, 63, 50, 51, 63, 57, 45, 63, 60, 41, 63, 61, 18,
      63, 63, 14, 63, 63, 17, 63, 63, 21, 63, 63, 24, 63, 63, 28, 63, 63, 33
);

IMPLEMENTATION

uses graphics, shapes;

procedure showpalette;
var x, y: word;
    color: byte;
begin
    for color := 16 to 231 do begin
        x := (color - 16) mod 18 * 14 + 34;
        y := (color - 16) div 18 * 14 + 16;
        block(x, y, x+12, y+12, color);
    end;
end;

procedure fade(smoothing: byte); assembler {
    Darkens and washes out VGA palette
};
asm
    mov bx, 231; {color number}
    @@fadeloop:
        mov ax, 1015h; {get RGB of color #bl (#bx)}
        int 10h
        add dh, [smoothing]; {red}
        add ch, [smoothing]; {green}
        add cl, [smoothing]; {blue}
        shr dh, 1
        shr cx, 1
        mov ax, 1010h; {set RGB of color #bl (#bx)}
        int 10h
        sub bx, 1; {previous color}
        mov cl, bl; {synchronize loop counter with color number}
        sub cl, 16; {except make sure we stop before base 16 colors}
    jnz @@fadeloop
end;

procedure setpalette(const palette: Palette216); assembler;
asm
    push ds          {DS is used by LDS, preserve value for after we're done}
    cld              {clear direction flag, auto-advance `palette` on read}
    lds  si, palette {make [ds:si] point to `palette`}
    mov  bx, 16      {start with first extended color}
    @iterate:
        lodsb            {load next byte from `palette` into AL}
        mov   dh, al     {dh = red}
        lodsb            {load next byte from `palette` into AL}
        mov   ch, al     {ch = green}
        lodsb            {load next byte from `palette` into AL}
        mov   cl, al     {cl = blue}
        mov   ax, 1010h  {set RGB of color #bl (#bx)}
        int   10h
        add   bx, 1      {proceed to next color}
        cmp   bx, 232
    jl @iterate
    pop  ds          {restore DS}
end;

end.

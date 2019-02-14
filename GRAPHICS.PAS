{$A-,B-,D-,E-,F-,G+,I-,L-,N-,O-,P-,Q-,R-,S-,T-,V-,X-,Y-}
UNIT GRAPHICS {
    Implements a simplistic API for the VGA 320x200 pixel, 216 color mode.
    Actual number of available colors in this mode is 256, but this unit
    sets the VGA palette to an RGB array with 6 steps of R, G, B values:
    colors from 16 to 231 are all possible combinations of these steps;
    colors from 0 to 15 are preserved (16 basic colors);
    colors from 232 to 255 are wildcards.
    Currently compiles under 16-bit Turbo Pascal to just 1248 bytes!
};

INTERFACE

const getmaxx = 319;
      getmaxy = 199;

var rgb: array[0..5, 0..5, 0..5] of byte {
    holds color codes associated with R, G, B values: `rgb[3,0,5]`;
    avoids function call overheads (if it were function(r, g, b)) or
    having to compute values inline each time
};
procedure graphmode(boolstate: boolean) {
    switches between text and graphics modes
};
function putpixel(x, y: word; color: byte): boolean {
    sets color of pixel at `x` and `y` to `color`
};
function getpixel(x, y: word; var color: byte): boolean {
    pushes color code of pixel at `x` and `y` into `color`
};
procedure fillscreen(color: byte) {
    fills screen with `color`; fillscreen(0) can be used to clear screen
};
procedure resetcolors {
    restores full saturation 216 color palette
};

IMPLEMENTATION

var vga_palette: array[0..767] of byte;

procedure resetcolors; assembler {
    Sets the VGA palette to an RGB array with 6 steps of each color
};
asm
    mov bx, 16; {start with color 16}
    @@paletteloop:
        mov ax, bx; {dividend}
        sub ax, 16
        mov dl, 6; {divisor}
        div dl
        mov cl, ah; {move remainder to blue register}
        mov ah, 0; {make sure ax = al, our quotient}
        div dl
        mov ch, ah; {move remainder to green register}
        mov dh, al; {move quotient to red register}
        ; {now exponentiate red}
        mov dl, cl; {cl is used for SHL, but we'll need it later}
        mov cl, dh
        add cl, 1
        mov dh, 1
        shl dh, cl
        sub dh, 2
        mov cl, dl; {restore rescued value of cl}
        ; {now exponentiate green}
        mov dl, cl; {cl is used for SHL, but we'll need it later}
        mov cl, ch
        add cl, 1
        mov ch, 1
        shl ch, cl
        sub ch, 2
        mov cl, dl; {restore rescued value of cl}
        ; {now exponentiate blue:}
        add cl, 1
        mov dl, 1; {cl is used for SHL, so we calculate in an unused register}
        shl dl, cl
        sub dl, 2
        mov cl, dl; {put blue where it belongs}
        ; {set RGB color of #bx}
        mov ax, 1010h
        int 10h
        add bx, 1; {proceed to next color}
    cmp bx, 232; {until all 216 colors filled}
    jl @@paletteloop
end;

procedure graphmode(boolstate: boolean) {
    Switches between text and graphics modes.
    * with `boolstate=true` enters 320x200x216 graphics mode;
      with `boolstate=false` returns to text mode and
          restores default VGA palette.
};
type FlatRGBArray = array[0..215] of byte;
var color: byte;
    pal_ptr: ^byte;
    pflatarray: ^FlatRGBArray;
begin
    pal_ptr := @vga_palette; {make local variable point to global}
    if boolstate then begin
        asm
            mov ax, 13h          {set 320x240x256 graphics mode}
            int 10h
            push es
            cld                  {clear DF, auto-advance arrays on write}
            les  di, pal_ptr     {point [es:di] to `vga_palette`}
            mov  bx, 0           {start with first color}
            @iterate_copyaway:   {fill VGA palette with stored `vga_palette`}
                mov   ax, 1015h  {get RGB of color #bl (#bx)}
                int   10h
                mov   al, dh     {dh = read}
                stosb            {copy AL into next pos of `vga_palette`}
                mov   al, ch     {ch = green}
                stosb            {copy AL into next pos of `vga_palette`}
                mov   al, cl     {cl = blue}
                stosb            {copy AL into next pos of `vga_palette`}
                add   bx, 1      {proceed to next color}
                cmp   bx, 256
            jl @iterate_copyaway
            pop es               {restore ES}
        end;
        pflatarray := @rgb; {fill `rgb` as if it was a one-dimensional array}
            for color := 0 to 215 do
                pflatarray^[color] := color + 16;
        resetcolors;
    end
    else asm
        push ds              {DS will be overwritten by LDS}
        cld                  {clear DF, auto-advance arrays on read}
        lds  si, pal_ptr     {point [ds:si] to `vga_palette`}
        mov  bx, 0           {start with first color}
        @iterate_copyback:   {fill VGA palette with stored `vga_palette`}
            lodsb            {load next byte from `palette` into AL}
            mov   dh, al     {dh = red}
            lodsb            {load next byte from `palette` into AL}
            mov   ch, al     {ch = green}
            lodsb            {load next byte from `palette` into AL}
            mov   cl, al     {cl = blue}
            mov   ax, 1010h  {set RGB of color #bl (#bx)}
            int   10h
            add   bx, 1      {proceed to next color}
            cmp   bx, 256
        jl @iterate_copyback
        pop  ds              {restore DS}
        mov ax, 3            {set 80x25x16 text mode}
        int 10h
    end;
end;

function putpixel(x, y: word; color: byte): boolean {
    Sets color of pixel at `x` and `y` using given R, G, B values;
    returns boolean value of success
};
begin
    if (x <= getmaxx) and (y <= getmaxy) then begin
        mem[$A000: y shl 8 + y shl 6 + x {320 * y + x}] := color;
        putpixel := true;
    end
    else
        putpixel := false;
end;

function getpixel(x, y: word; var color: byte): boolean {
    Pushes color code of pixel at `x` and `y` into `color`;
    returns boolean value of success
};
begin
    if (x <= getmaxx) and (y <= getmaxy) then begin
        color := mem[$A000: y shl 8 + y shl 6 + x {320 * y + x}];
        getpixel := true;
    end
    else
        getpixel := false;
end;

procedure fillscreen(color: byte) {
    Fills screen with `color`; fillscreen(0) can be used to clear screen
};
begin
    fillchar(mem[$A000:0], 64000, color);
end;

end.

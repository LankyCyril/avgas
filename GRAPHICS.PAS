{$A-,B-,D+,E-,F-,G+,I-,L+,N-,O-,P-,Q-,R+,S-,T-,V+,X+,Y+}
UNIT GRAPHICS {
    Implements a simplistic API for the VGA 320x200 pixel, 216 color mode.
    Actual number of available colors in this mode is 256, but this unit
    sets the VGA palette to an RGB array with 6 steps of R, G, B values:
    colors from 16 to 231 are all possible combinations of these steps;
    colors from 0 to 15 are preserved (16 basic colors);
    colors from 232 to 255 are wildcards.
    This unit currently compiles under 16-bit Turbo Pascal
    just to 3168 bytes!
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
procedure fade(smoothing: byte) {
    darkens and washes out VGA palette
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

(*  asm mov ax, 1010h end; {set RGB of color #bx}
    asm mov bx, 16 end; {only operate on extended colors}
    asm mov dh, 0 end; {red}
    for r := 0 to 5 do begin
        asm shl dh, 1 end;
        asm mov ch, 0 end; {green}
        for g := 0 to 5 do begin
            asm shl ch, 1 end;
            asm mov cl, 0 end; {blue}
            for b := 0 to 5 do asm
                shl cl, 1
                int 10h
                add bx, 1
                add cl, 1
            end;
            asm add ch, 1 end;
        end;
        asm add dh, 1 end;
    end;*)

const COPY_AWAY = $1015;
      COPY_BACK = $1010;

procedure graphmode(boolstate: boolean) {
    Switches between text and graphics modes.
    * with `boolstate=true` enters 320x200x216 graphics mode;
      with `boolstate=false` returns to text mode and
          restores default VGA palette.
    Uses a relatively expensive method to save and restore the VGA palette
    (avoids memory addressing from assembly and instead transfers values one
    by one to/from a Pascal array after polling each color register with
    assembly), but this has good hardware support.
    For a quicker method, but with poorer hardware support, use
    procedure graphmode() from unit GRAPHEXT.
};
type FlatRGBArray = array[0..215] of byte;
var ax_instruction: word;
    color, r, g, b: byte;
    shift: word;
    pflatarray: ^FlatRGBArray;
begin
    if boolstate then begin
        asm mov ax, 13h end; {set 320x240x256 graphics mode}
        asm int 10h end;
        ax_instruction := COPY_AWAY;
    end
    else
        ax_instruction := COPY_BACK;
    for color := 0 to 255 do begin {copy palette}
        shift := color shl 1 + color;
        asm mov ax, [ax_instruction] end; {get or set RGB of color #bl}
        asm mov bl, [color] end;
        if ax_instruction = COPY_AWAY then begin
            asm int 10h end;
            asm mov [r], dh end;
            asm mov [g], ch end;
            asm mov [b], cl end;
            vga_palette[shift] := r;
            vga_palette[shift+1] := g;
            vga_palette[shift+2] := b;
        end;
        if ax_instruction = COPY_BACK then begin
            r := vga_palette[shift];
            g := vga_palette[shift+1];
            b := vga_palette[shift+2];
            asm mov dh, [r] end;
            asm mov ch, [g] end;
            asm mov cl, [b] end;
            asm int 10h end;
        end;
    end;
    if boolstate then begin
        pflatarray := @rgb; {fill `rgb` as if it was a one-dimensional array}
            for color := 0 to 215 do
                pflatarray^[color] := color + 16;
        resetcolors;
    end
    else asm
        mov ax, 3; {set 80x25x16 text mode}
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

end.

{$A-,B-,D+,E-,F-,G+,I-,L+,N-,O-,P-,Q-,R+,S-,T-,V+,X+,Y+}
UNIT GRAPHICS {
    Implements a simplistic API for the VGA 320x200 pixel, 216 color mode.
    Actual number of available colors in this mode is 256, but this unit
    sets the VGA palette to an RGB array with 6 steps of R, G, B values:
    colors from 16 to 231 are all possible combinations of these steps;
    colors from 0 to 15 are preserved (16 basic colors);
    colors from 232 to 255 are undefined.
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
procedure fill_rgb_array {
    internal function, exposed only for use in module GRAPHEXT
};

IMPLEMENTATION

var vga_palette: array[0..767] of byte;

procedure fill_rgb_array {
    Quickly fills `rgb` with color codes;
    allows `putpixel(x, y, rgb[3,0,5])` etc
};
type FlatRGBArray = array[0..215] of byte;
var pflatarray: ^FlatRGBArray;
    i: byte;
begin
    pflatarray := @rgb; {fill `rgb` as if it was a one-dimensional array}
    for i := 0 to 215 do
        pflatarray^[i] := i + 16;
end;

procedure resetcolors {
    Sets the VGA palette to an RGB array with 6 steps of each color
};
var r, g, b: byte;
begin
    asm mov ax, 1010h end; {set RGB of color #bx}
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
    end;
end;

const COPY_AWAY = $1015;
      COPY_BACK = $1010;

procedure copy_vga_palette(ax_instruction: word) {
    Saves and restores VGA palette by iterating over palette registers;
    this is relatively expensive (avoids memory addressing from assembly
    and instead transfers values one by one to/from a Pascal array after
    polling each color register with assembly),
    but has better hardware support.
};
var color, r, g, b: byte;
    shift: word;
begin
    for color := 0 to 255 do begin
        shift := color * 3;
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
end;

procedure graphmode(boolstate: boolean) {
    Switches between text and graphics modes.
    * with `boolstate=true` enters 320x200x216 graphics mode;
      with `boolstate=false` returns to text mode and
          restores default VGA palette.
    Uses a relatively slow method to save and restore the VGA palette
    (copy_vga_palette). For a quicker method, but with poorer hardware
    support, use procedure graphmode() from unit GRAPHEXT.
};
begin
    if boolstate then begin
        asm mov ax, 13h end; {set 320x240x256 graphics mode}
        asm int 10h end;
        copy_vga_palette(COPY_AWAY);
        resetcolors;
        fill_rgb_array;
    end;
    if not boolstate then begin
        copy_vga_palette(COPY_BACK);
        asm mov ax, 3 end; {set 80x25x16 text mode}
        asm int 10h end;
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

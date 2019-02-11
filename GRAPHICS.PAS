{$A-,B-,D+,E+,F-,G+,I-,L+,N-,O-,P-,Q-,R+,S-,T-,V+,X+,Y+}
UNIT GRAPHICS {
    Implements a simplistic API for the VGA 320x200 pixel, 256 color mode.
    Sets the VGA palette to an RGB array with 6 steps of R, G, B values:
    colors from 0 to 215 are all possible combinations of these steps;
    colors from 216 to 255 are undefined
};

INTERFACE

const getmaxx = 319;
      getmaxy = 199;

procedure graphmode(boolstate: boolean) {
    graphmode(true) enters 320x200x216 graphics mode;
    graphmode(false) returns to text mode and restores default VGA palette
};
function putrgb(x, y: word; r, g, b: byte): boolean {
    sets color of pixel at `x` and `y` using given R, G, B values
};
function getrgb(x, y: word; var r, g, b: byte): boolean {
    pushes R, G, B values of pixel at `x` and `y` into `r`, `g`, and `b`
};
procedure fade(smoothing: byte) {
    darkens and washes out VGA palette
};
procedure reset_colors {
    restores full saturation 216 color palette
};

IMPLEMENTATION

var vga_palette: array[0..767] of byte;

procedure set_216_palette {
    Sets the VGA palette to an RGB array with 6 steps of each color
};
var r, g, b: byte;
begin
    asm mov ax, 1010h end;
    asm mov bx, 0 end;
    asm mov dh, 0 end;
    for r := 0 to 5 do begin
        asm shl dh, 1 end;
        asm mov ch, 0 end;
        for g := 0 to 5 do begin
            asm shl ch, 1 end;
            asm mov cl, 0 end;
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

procedure graphmode(boolstate: boolean) {
    graphmode(true) enters 320x200x216 graphics mode;
    graphmode(false) returns to text mode and restores default VGA palette
};
begin
    asm
        mov bx, 0
        mov cx, 256
        mov es, [seg vga_palette]
        mov dx, [offset vga_palette]
    end;
    if boolstate then asm
        mov ax, 1017h
        int 10h
        mov ax, 13h
    end
    else asm
        mov ax, 1012h
        int 10h
        mov ax, 3
    end;
    asm int 10h end;
    if boolstate then
        set_216_palette;
end;

function putrgb(x, y: word; r, g, b: byte): boolean {
    Sets color of pixel at `x` and `y` using given R, G, B values;
    returns boolean value of success
};
begin
    if (x <= getmaxx) and (y <= getmaxy)
    and (r < 6) and (g < 6) and (b < 6) then begin
        mem[$A000: y shl 8 + y shl 6 + x] := (
            r shl 5 + (r + g) shl 2 + g shl 1 + b
        );
        putrgb := true;
    end
    else
        putrgb := false;
end;

function getrgb(x, y: word; var r, g, b: byte): boolean {
    Pushes R, G, B values of pixel at `x` and `y` into `r`, `g`, and `b`;
    returns boolean value of success
};
begin
    if (x <= getmaxx) and (y <= getmaxy) then begin
        b := mem[$A000: y shl 8 + y shl 6 + x];
        r := b shr 2 div 9;
        b := b - r shl 5 - r shl 2;
        g := b shr 1 div 3;
        b := b - g shl 2 - g shl 1;
        getrgb := true;
    end
    else
        getrgb := false;
end;

procedure fade(smoothing: byte) {
    Darkens and washes out VGA palette
};
var i: byte;
begin
    for i := 0 to 255 do asm
        mov bx, [word(i)]
        mov ax, 1015h
        int 10h
        add dh, [smoothing]
        add ch, [smoothing]
        add cl, [smoothing]
        shr dh, 1
        shr cx, 1
        mov ax, 1010h
        int 10h
    end;
end;

procedure reset_colors {
    Restores full saturation 216 color palette
}; begin set_216_palette; end;

end.

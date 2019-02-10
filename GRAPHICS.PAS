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
function putrgb(x, y: integer; r, g, b: byte): boolean {
    sets color of pixel at `x` and `y` using given R, G, B values
};
function getrgb(x, y: integer; var r, g, b: byte): boolean {
    pushes R, G, B values of pixel at `x` and `y` into `r`, `g`, and `b`
};

IMPLEMENTATION

var vga_palette: array[0..767] of byte;

procedure savevgapalette; assembler {
    Stores current VGA color table in `vga_palette`
};
asm
   mov ax, 1017h
   mov bx, 0
   mov cx, 256
   mov es, [seg vga_palette]
   mov dx, [offset vga_palette]
   int 10h
end;

procedure restorevgapalette; assembler {
    Writes RGB values from `vga_palette` into the VGA color table
};
asm
   mov ax, 1012h
   mov bx, 0
   mov cx, 256
   mov es, [seg vga_palette]
   mov dx, [offset vga_palette]
   int 10h
end;

procedure set216palette {
    Sets the VGA palette to an RGB array with 6 steps of each color
};
var r, g, b: byte;
    i: word;
begin
    i := 0;
    for r := 0 to 60 do if r mod 12 = 0 then
        for g := 0 to 60 do if g mod 12 = 0 then
            for b := 0 to 60 do if b mod 12 = 0 then begin
                asm
                   mov ax, 1010h
                   mov bx, [i]
                   mov dh, [r]
                   mov ch, [g]
                   mov cl, [b]
                   int 10h
                end;
                inc(i);
            end;
end;

procedure graphmode(boolstate: boolean) {
    graphmode(true) enters 320x200x216 graphics mode;
    graphmode(false) returns to text mode and restores default VGA palette
};
begin
    if boolstate then begin
        savevgapalette;
        asm mov ax, 13h end;
    end
    else begin
        restorevgapalette;
        asm mov ax, 3 end;
    end;
    asm int 10h end;
    if boolstate then
        set216palette;
end;

function are_valid_coords(x, y: integer): boolean {
    returns true if `x` and `y` are within screen bounds, false otherwise
};
begin
    are_valid_coords := (
        (0 <= x) and (x <= getmaxx) and (0 <= y) and (y <= getmaxy)
    );
end;

function putrgb(x, y: integer; r, g, b: byte): boolean {
    Sets color of pixel at `x` and `y` using given R, G, B values;
    returns boolean value of success
};
var rgb: integer;
begin
    putrgb := false;
    if are_valid_coords(x, y) then begin
        if (r > 5) or (g > 5) or (b > 5) then
            rgb := -1
        else
            rgb := r*36 + g*6 + b;
        if rgb <> -1 then begin
            mem[$A000: y*320 + x] := rgb;
            putrgb := true;
        end;
    end;
end;

function getrgb(x, y: integer; var r, g, b: byte): boolean {
    Pushes R, G, B values of pixel at `x` and `y` into `r`, `g`, and `b`;
    returns boolean value of success
};
var rgb: integer;
begin
    if are_valid_coords(x, y) then
        rgb := mem[$A000: y*320 + x]
    else
        rgb := -1;
    getrgb := (rgb <> -1);
    if rgb <> -1 then begin
        r := rgb div 36;
        g := (rgb mod 36) div 6;
        b := rgb mod 6;
    end;
end;

end.
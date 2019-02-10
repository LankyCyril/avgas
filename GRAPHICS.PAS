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

uses dos;

var vga_palette: array[0..767] of byte;
    reg: registers;

procedure savevgapalette {
    Stores current VGA color table in `vga_palette`
};
begin
    fillchar(reg, sizeof(reg), 0);
    with reg do begin
         ax := $1017;
         bx := 0;
         cx := 256;
         es := seg(vga_palette);
         dx := ofs(vga_palette);
    end;
    intr($10, reg);
end;

procedure pushpalette(palette: array of byte) {
    Writes RGB values from `palette` into the VGA color table
};
begin
    fillchar(reg, sizeof(reg), 0);
    with reg do begin
         ax := $1012;
         bx := 0;
         cx := 256;
         es := seg(palette);
         dx := ofs(palette);
    end;
    intr($10, reg);
end;

procedure set216palette {
    Sets the VGA palette to an RGB array with 6 steps of each color
};
var palette: array[0..767] of byte;
    r, g, b: byte;
    i: word;
begin
    i := 0;
    for r := 0 to 5 do
        for g := 0 to 5 do
            for b := 0 to 5 do begin
                palette[i] := r*12;
                palette[i+1] := g*12;
                palette[i+2] := b*12;
                i := i + 3
            end;
    pushpalette(palette);
end;

procedure graphmode(boolstate: boolean) {
    graphmode(true) enters 320x200x216 graphics mode;
    graphmode(false) returns to text mode and restores default VGA palette
};
begin
    fillchar(reg, sizeof(reg), 0);
    if boolstate then begin
        savevgapalette;
        reg.ax := $0013;
    end
    else begin
        pushpalette(vga_palette);
        reg.ax := $0003;
    end;
    intr($10, reg);
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
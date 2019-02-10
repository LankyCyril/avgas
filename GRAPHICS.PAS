UNIT GRAPHICS {
    Implements a simplistic API for the VGA 320x200 pixel, 256 color mode.
    Sets the VGA palette to an RGB array with 6 steps of R, G, B values:
    colors from 0 to 215 are all possible combinations of these steps;
    colors from 216 to 255 are undefined
};

INTERFACE

type RGB_record = record r, g, b: byte; end;
type ColorPalette = array[byte] of RGB_record;

const getmaxx = 319;
const getmaxy = 199;

procedure graphmode(boolstate: boolean) {switches graphics on and off};
function rgb(r, g, b: byte): integer {converts R, G, B to color number};

function pushrgb(x, y: integer; r, g, b: byte): integer {
    sets color of pixel at `x` and `y` using given R, G, B values
};
function savergb(x, y: integer; var rgb_value: RGB_record): integer {
    stores R, G, B values of pixel at `x` and `y` in variable `rgb_value`
};

IMPLEMENTATION

uses dos;

type VgaArray = array[0..getmaxy, 0..getmaxx] of byte;
var  screen_array: VgaArray absolute $A000:$0000;
var  default_palette: ColorPalette;

procedure savepalette(var palette: ColorPalette) {
    Stores current VGA color table in `palette`
};
var reg: registers;
    i: byte;
begin
    fillchar(reg, sizeof(reg), 0);
    with reg do begin
         ax := $1017;
         bx := 0;
         cx := 256;
         es := seg(palette);
         dx := ofs(palette);
    end;
    intr($10, reg);
end;

procedure pushpalette(palette: ColorPalette) {
    Writes RGB values from `palette` into the VGA color table
};
var reg: registers;
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

function rgb(r, g, b: byte): integer {
    Converts R, G, B to color number; returns -1 if values out of bounds
};
begin
    if (r > 5) or (g > 5) or (b > 5) then
        rgb := -1
    else
        rgb := r*36 + g*6 + b;
end;

procedure set216palette {
    Sets the VGA palette to an RGB array with 6 steps of each color
};
var palette: ColorPalette;
    r, g, b, color: byte;
    rgb_color: RGB_record;
begin
    for r := 0 to 5 do
        for g := 0 to 5 do
            for b := 0 to 5 do begin
                rgb_color.r := r*12;
                rgb_color.g := g*12;
                rgb_color.b := b*12;
                palette[rgb(r, g, b)] := rgb_color;
            end;
    pushpalette(palette);
end;

procedure graphmode(boolstate: boolean) {
    graphmode(true) enters 320x200x216 graphics mode;
    graphmode(false) returns to text mode and restores default VGA palette
};
var reg: registers;
begin
    fillchar(reg, sizeof(reg), 0);
    if boolstate then begin
        savepalette(default_palette);
        reg.ax := $0013;
    end
    else begin
        pushpalette(default_palette);
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
        (0 <= x) and (x <= getmaxx) and
        (0 <= y) and (y <= getmaxy)
    );
end;

function putpixel(x, y: integer; color: byte): integer {
    puts pixel at `x` and `y` using color from current palette;
    returns 1 on success, -1 if `x` or `y` are out of screen bounds
};
begin
    if are_valid_coords(x, y) then begin
        screen_array[y, x] := color;
        putpixel := 1;
    end
    else
        putpixel := -1;
end;

function getpixel(x, y: integer): integer {
    gets color code of pixel at `x` and `y`;
    returns color code (from 0 to 255) on success,
    -1 if `x` or `y` are out of screen bounds
};
begin
    if are_valid_coords(x, y) then
        getpixel := screen_array[y, x]
    else
        getpixel := -1;
end;

function pushrgb(x, y: integer; r, g, b: byte): integer {
    Sets color of pixel at `x` and `y` using given R, G, B values;
    returns 1 on success, -1 if `x` or `y` are out of screen bounds
    or either of the R, G, B values out of gradient step bounds
};
var color: integer;
begin
    color := rgb(r, g, b);
    if color <> -1 then
        pushrgb := putpixel(x, y, color)
    else
        pushrgb := -1;
end;

function savergb(x, y: integer; var rgb_value: RGB_record): integer {
    Stores R, G, B values of pixel at `x` and `y` in variable `rgb_value`;
    returns 1 on success, -1 if `x` or `y` are out of screen bounds
};
var color: integer;
begin
    color := getpixel(x, y);
    rgb_value.r := color div 36;
    rgb_value.g := (color mod 36) div 6;
    rgb_value.b := color mod 6;
    savergb := color;
end;

end.
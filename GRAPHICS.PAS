unit graphics;

interface

type RGB_record = record r, g, b: byte; end;
type ColorPalette = array[byte] of RGB_record;

const getmaxx = 319;
const getmaxy = 199;

procedure graphmode(boolstate: boolean);
function rgb(r, g, b: byte): integer;
function putpixel(x, y: integer; color: byte): boolean;
function getpixel(x, y: integer): integer;

implementation

uses dos;

type VgaArray = array[0..getmaxy, 0..getmaxx] of byte;
var  screen_array: VgaArray absolute $A000:$0000;
var  default_palette: ColorPalette;
var  rgb_black: RGB_record;

procedure savepalette(var palette: ColorPalette);
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
    for i := 0 to 255 do
        with palette[i] do begin
             r := r shl 2;
             g := g shl 2;
             b := b shl 2;
        end;
end;

procedure pushpalette(palette: ColorPalette);
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

function rgb(r, g, b: byte): integer;
begin
    if (r > 5) or (g > 5) or (b > 5) then
        rgb := -1
    else
        rgb := r*36 + g*6 + b;
end;

procedure set216palette;
var palette: ColorPalette;
    r, g, b, color: byte;
    rgb_color: RGB_record;
begin
    for r := 0 to 5 do
        for g := 0 to 5 do
            for b := 0 to 5 do begin
                color := rgb(r, g, b);
                rgb_color.r := r*12;
                rgb_color.g := g*12;
                rgb_color.b := b*12;
                palette[color] := rgb_color;
            end;
    for color := 216 to 255 do
        palette[color] := rgb_black;
    pushpalette(palette);
end;

procedure graphmode(boolstate: boolean);
{ graphmode(true) enters 320x200x216 graphics mode }
{ graphmode(false) returns to text mode; }
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

function are_valid_coords(x, y: integer): boolean;
{ return true if `x in [0..getmaxx]` and `y in [0..getmaxy]` }
begin
    are_valid_coords := (
        (0 <= x) and (x <= getmaxx) and
        (0 <= y) and (y <= getmaxy)
    );
end;

function putpixel(x, y: integer; color: byte): boolean;
{ puts pixel; returns true on success, false if x or y out of range }
begin
    if are_valid_coords(x, y) then begin
        screen_array[y, x] := color;
        putpixel := true;
    end
    else
        putpixel := false;
end;

function getpixel(x, y: integer): integer;
{ gets pixel; returns value 0..255 on success, -1 if x or y out of range }
begin
    if are_valid_coords(x, y) then
        getpixel := screen_array[y, x]
    else
        getpixel := -1;
end;

end.
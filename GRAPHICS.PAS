unit graphics;

interface

type
    RGB = record
        red: byte; green: byte; blue: byte;
    end;
    ColorTable = array[byte] of RGB;

const
    getmaxx = 319;
    getmaxy = 199;

procedure graphmode(boolstate: boolean);
procedure getpalette(var palette: ColorTable);
function putpixel(x, y: integer; color: byte): boolean;
function getpixel(x, y: integer): integer;

implementation

uses dos;

type VgaArray = array[0..getmaxy, 0..getmaxx] of byte;
var  screen_array: VgaArray absolute $A000:$0000;

procedure graphmode(boolstate: boolean);
{ graphmode(true) enters 320x240x256 graphics mode }
{ graphmode(false) returns to text mode; }
var reg: registers;
begin
    fillchar(reg, sizeof(reg), 0);
    if boolstate then
        reg.ax := $0013
    else
        reg.ax := $0003;
    intr($10, reg);
end;

procedure getpalette(var palette: ColorTable);
var
    reg: registers;
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
             red := red shl 2;
             green := green shl 2;
             blue := blue shl 2;
        end;
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
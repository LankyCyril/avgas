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

const MOVE_AWAY = $1017;
      MOVE_BACK = $1012;

var vga_palette: array[0..767] of byte;

procedure movevgapalette(ax_instr: word); assembler {
    Stores current VGA color table in `vga_palette`
};
asm
    mov ax, [ax_instr]
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
begin
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
                mov ax, 1010h
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
    if boolstate then begin
        movevgapalette(MOVE_AWAY);
        asm mov ax, 13h end;
    end
    else begin
        movevgapalette(MOVE_BACK);
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

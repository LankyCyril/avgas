{$A-,B-,D-,E-,F-,G+,I-,L-,N-,O-,P-,Q-,R+,S-,T-,V-,X-,Y-}
UNIT GRAPHEXT;

INTERFACE

var rgb: array[0..5, 0..5, 0..5] of byte {
    holds color codes associated with R, G, B values: `rgb[3,0,5]`;
    avoids function call overheads (if it were function(r, g, b)) or
    having to compute values inline each time
};
procedure graphmode(boolstate: boolean) {
    switches between text and graphics modes; redefines the procedure
    from unit GRAPHICS
};

var vga_palette: array[0..767] of byte;

IMPLEMENTATION

uses graphics;

const MOVE_AWAY = $1017;
      MOVE_BACK = $1012;

procedure graphmode(boolstate: boolean) {
    Switches between text and graphics modes.
    * with `boolstate=true` enters 320x200x216 graphics mode;
      with `boolstate=false` returns to text mode and
          restores default VGA palette.
    Uses a fast native method to save and restore the VGA palette
    (with AX=1017h and AX=1012h, by writing/reading the full palette to/from
    an array at es:dx). However, this is dependent on the specific hardware
    implementation and may not work. For a more reliable, but slower, method
    use procedure graphmode() from unit GRAPHICS. In other words, if you are
    falling back to the slower method, just don't import GRAPHEXT.
};
type FlatRGBArray = array[0..215] of byte;
var pflatarray: ^FlatRGBArray;
    color: byte;
begin
    if boolstate then asm
        mov ax, 13h; {set 320x240x256 graphics mode}
        int 10h
        mov ax, [MOVE_AWAY]
    end
    else
        asm mov ax, [MOVE_BACK] end;
    asm
        mov bx, 0
        mov cx, 256
        mov es, [seg vga_palette]
        mov dx, [offset vga_palette]
        int 10h
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

end.

UNIT GRAPHEXT;

INTERFACE

procedure graphmode(boolstate: boolean) {
    switches between text and graphics modes; redefines the procedure
    from unit GRAPHICS
};

IMPLEMENTATION

uses graphics;

var vga_palette: array[0..767] of byte;

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
        mov ax, 1017h; {push/pop #cx RGB colors to/from memory at es:dx}
        int 10h
    end;
    if boolstate then begin
        resetcolors;
        fill_rgb_array;
    end
    else asm
        mov ax, 3; {set 80x25x16 text mode}
        int 10h
    end;
end;

end.

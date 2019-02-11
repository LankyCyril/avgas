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

procedure graphmode(boolstate, palquicksave: boolean) {
    switches between text and graphics modes
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

const MOVE_AWAY=$1017;
      MOVE_BACK=$1012;
      COPY_AWAY=$1015;
      COPY_BACK=$1010;

var vga_palette: array[0..767] of byte;

procedure reset_colors {
    Sets the VGA palette to an RGB array with 6 steps of each color
};
var r, g, b: byte;
begin
    asm mov ax, 1010h end; {set RGB of color #bx}
    asm mov bx, 16 end;
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

procedure move_vga_palette(ax_instruction: word); assembler {
    Saves and restores VGA palette via AX=1017h and AX=1012h instructions;
    may not work on some hardware.
};
asm
    mov ax, [ax_instruction]
    mov bx, 0
    mov cx, 256
    mov es, [seg vga_palette]
    mov dx, [offset vga_palette]
    mov ax, 1017h; {push or pop #cx RGB colors to/from memory at es:dx}
    int 10h
end;

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

procedure graphmode(boolstate, palquicksave: boolean) {
    Switches between text and graphics modes.
    * with `boolstate=true` enters 320x200x216 graphics mode;
      with `boolstate=false` returns to text mode and
          restores default VGA palette.
    * with `palquicksave=true` saves and restores VGA palette via
          AX=1017h and AX=1012h instructions; may not work on some hardware;
    * with `palquicksave=false` saves and restores VGA palette by
          iterating over palette registers; this is more expensive but has
          better hardware support.
};
begin
    if boolstate then begin
        asm mov ax, 13h end; {set 320x240x256 graphics mode}
        asm int 10h end;
        if palquicksave then
            move_vga_palette(MOVE_AWAY)
        else
            copy_vga_palette(COPY_AWAY);
        reset_colors;
    end;
    if not boolstate then begin
        if palquicksave then
            move_vga_palette(MOVE_BACK)
        else
            copy_vga_palette(COPY_BACK);
        asm mov ax, 3 end; {set 80x25x16 text mode}
        asm int 10h end;
    end;
end;

function putrgb(x, y: word; r, g, b: byte): boolean {
    Sets color of pixel at `x` and `y` using given R, G, B values;
    returns boolean value of success
};
begin
    if (x <= getmaxx) and (y <= getmaxy)
    and (r < 6) and (g < 6) and (b < 6) then begin
        mem[$A000: y shl 8 + y shl 6 + x {320 * y + x}] :=
            r shl 5 + (r + g) shl 2 + g shl 1 + b + 16;
            {r * 36 + g * 6 + b + 16}
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
        b := mem[$A000: y shl 8 + y shl 6 + x {320 * y + x}] - 16;
        r := b shr 2 div 9; {b div 36}
        b := b - r shl 5 - r shl 2; {b mod 36}
        g := b shr 1 div 3; {b div 6}
        b := b - g shl 2 - g shl 1; {b mod 6}
        getrgb := true;
    end
    else
        getrgb := false;
end;

procedure fade(smoothing: byte); assembler {
    Darkens and washes out VGA palette
};
asm
    mov bx, 255; {color number}
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
        sub bx, 1;  {previous color}
        mov cl, bl; {decrease loop counter, was overwritten}
        sub cl, 16;
    jnz @@fadeloop
end;

end.

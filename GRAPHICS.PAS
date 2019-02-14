{$A-,B-,D-,E-,F-,G+,I-,L-,N-,O-,P-,Q-,R-,S-,T-,V-,X-,Y-}
UNIT GRAPHICS {
    Implements a simplistic API for the VGA 320x200 pixel, 216+ color mode.
    Actual number of available colors in this mode is 256, but this unit
    sets the VGA palette to an RGB array with 6 steps of R, G, B values:
    colors from 16 to 231 are all possible combinations of these steps;
    colors from 0 to 15 are preserved (16 basic colors);
    colors from 232 to 255 are wildcards.
    Currently compiles under 16-bit Turbo Pascal to just 1264 bytes!
};

INTERFACE

const getmaxx = 319;
      getmaxy = 199;

var rgb: array[0..5, 0..5, 0..5] of byte {
    holds color codes associated with R, G, B values: `rgb[3,0,5]`;
    avoids function call overheads (if it were function(r, g, b)) or
    having to compute values inline each time
};
procedure graphmode(const boolstate: boolean) {
    switches between text and graphics modes
};
function putpixel(x, y: word; color: byte): boolean {
    sets color of pixel at `x` and `y` to `color`
};
function getpixel(x, y: word; var color: byte): boolean {
    pushes color code of pixel at `x` and `y` into `color`
};
procedure fillscreen(color: byte) {
    fills screen with `color`; fillscreen(0) can be used to clear screen
};
procedure resetcolors {
    restores full saturation 216 color palette
};

IMPLEMENTATION

var vga_palette: array[0..767] of byte;

procedure resetcolors; assembler {
    Sets the VGA palette to an RGB array with 6 steps of each color
};
asm
    mov bx, 16        {start with color 16}
    @loop_resetcolors:
        mov ax, bx    {dividend}
        sub ax, 16
        mov dl, 6     {divisor}
        div dl
        mov cl, ah    {move remainder to blue register}
        mov ah, 0     {make sure AX = AL, our quotient}
        div dl
        mov ch, ah    {move remainder to green register}
        mov dh, al    {move quotient to red register}
        {now exponentiate red}
        mov dl, cl    {CL is used for SHL, but we'll need it later}
        mov cl, dh
        add cl, 1
        mov dh, 1
        shl dh, cl
        sub dh, 2     {DH = 1 SHL (DH + 1) - 2}
        mov cl, dl    {restore rescued value of CL}
        {now exponentiate green}
        mov dl, cl    {CL is used for SHL, but we'll need it later}
        mov cl, ch
        add cl, 1
        mov ch, 1
        shl ch, cl
        sub ch, 2     {CH = 1 SHL (CH + 1) - 2}
        mov cl, dl    {restore rescued value of CL}
        {now exponentiate blue}
        add cl, 1
        mov dl, 1     {CL is used for SHL, so we calculate in unused DL}
        shl dl, cl
        sub dl, 2
        mov cl, dl    {CL = 1 SHL (CL + 1) - 2}
        mov ax, 1010h {set RGB color of #BL (#BX)}
        int 10h
        add bx, 1     {proceed to next color}
        cmp bx, 232   {until all 216 colors filled}
        jl @loop_resetcolors
end;

procedure graphmode(const boolstate: boolean); assembler {
    Switches between text and graphics modes;
    * graphmode(true) enters 320x200x216+ graphics mode;
    * graphmode(false) returns to text mode and restores default VGA palette.
};
const {make local variables point to global ones}
      pal_ptr: ^byte = @vga_palette;
      rgb_ptr: ^byte = @rgb;
asm
    cld                      {clear DF, auto-advance arrays on write}
    mov bl, 0                {start with first color}
    cmp boolstate, 0
    je  @set_textmode
    @set_graphmode:
        mov  ax, 13h         {set 320x200x256 graphics mode}
        int  10h
        push es              {ES will be overwritten by LES}
        les  di, pal_ptr     {point [ES:DI] to `vga_palette`}
        @loop_copyaway:      {fill `vga_palette` with VGA palette}
            mov   ax, 1015h  {get RGB of color #BL}
            int   10h
            mov   al, dh     {DH = red}
            stosb            {copy AL into next byte of `vga_palette`}
            mov   ax, cx     {CX = green:blue}
            stosw            {copy AX into next two bytes of `vga_palette`}
            add   bl, 1      {proceed to next color}
            cmp   bl, 255    {until all colors 0..255 processed}
            jne   @loop_copyaway
        les   di, rgb_ptr    {point [ES:DI] to `rgb`}
        mov   al, 16         {start with first extended color}
        @loop_fillrgb:
            stosb            {put color number into next flat pos of `rgb`}
            add   al, 1      {proceed to next color}
            cmp   al, 232    {until all extended colors processed}
            jb    @loop_fillrgb
        pop   es
        call  resetcolors
        jmp   @finish_graphmode
    @set_textmode:
        push ds              {DS will be overwritten by LDS}
        lds  si, pal_ptr     {point [DS:SI] to `vga_palette`}
        @loop_copyback:      {fill VGA palette with stored `vga_palette`}
            lodsb            {load next byte from `vga_palette` into AL}
            mov   dh, al     {DH = red}
            lodsw            {load next two bytes from `va_palette` into AX}
            mov   cx, ax     {CX = green:blue}
            mov   ax, 1010h  {set RGB of color #BL}
            int   10h
            add   bl, 1      {proceed to next color}
            cmp   bl, 255    {until all colors 0..255 processed}
            jne   @loop_copyback
        pop  ds              {restore DS}
        mov  ax, 3           {set 80x25x16 text mode}
        int  10h
    @finish_graphmode:
end;

function putpixel(x, y: word; color: byte): boolean {
    Sets color of pixel at `x` and `y` using given R, G, B values;
    returns boolean value of success
};
begin
    if (x <= getmaxx) and (y <= getmaxy) then begin
        mem[$A000: y shl 8 + y shl 6 + x {320 * y + x}] := color;
        putpixel := true;
    end
    else
        putpixel := false;
end;

function getpixel(x, y: word; var color: byte): boolean {
    Pushes color code of pixel at `x` and `y` into `color`;
    returns boolean value of success
};
begin
    if (x <= getmaxx) and (y <= getmaxy) then begin
        color := mem[$A000: y shl 8 + y shl 6 + x {320 * y + x}];
        getpixel := true;
    end
    else
        getpixel := false;
end;

procedure fillscreen(color: byte) {
    Fills screen with `color`; fillscreen(0) can be used to clear screen
};
begin
    fillchar(mem[$A000:0], 64000, color);
end;

end.

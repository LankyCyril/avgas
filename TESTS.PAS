uses crt, graphics;

function shl_func(r, g, b: byte): byte;
begin
    shl_func := 2 shl 5 + (2 + 3) shl 2 + 3 shl 1 + 5 + 16;
end;

procedure rgb_arithmetic {
    Tests speeds of calculating the color code from R, G, B values;
    * inline SHL is the fastest;
    * inline MUL and array read are very close to SHL, very slightly slower;
    * call to function (even with SHL) has huge overhead and is very slow.
    Theoretically, even inline multiplication would be OK, but ideally,
    we want a solution where we can address a color by its R, G, B values
    without writing out the arithmetic every time.
    Function calls are too slow for this, therefore the array approach wins.
};
const maxi = 5;
      maxj = 65536*128;
var i, j: longint;
    color: byte;
begin
    clrscr;
    for i := 1 to maxi do begin
        for j := 1 to maxj do
            color := rgb[2,3,5];
        write('A');
        if keypressed then break;
    end;
    writeln;
    for i := 1 to maxi do begin
        for j := 1 to maxj do
            color := 2 shl 5 + (2 + 3) shl 2 + 3 shl 1 + 5 + 16;
        write('S');
        if keypressed then break;
    end;
    writeln;
    for i := 1 to maxi do begin
        for j := 1 to maxj do
            color := 2 * 36 + 3 * 6 + 5 + 16;
        write('M');
        if keypressed then break;
    end;
    writeln;
    for i := 1 to maxi do begin
        for j := 1 to maxj do
            color := shl_func(2, 3, 5);
        write('F');
        if keypressed then break;
    end;
    write('Press <ENTER> to quit');
    readln;
end;

procedure draw_blocks {
    Draw blocks either:
    * by calling multiple putpixel functions, or
    * by drawing each horizontal line with fillchar, or
    * by drawing each vertical line with an assembly loop
};
const maxi = 8; maxj = 1024;
      xdim = 12; ydim = 100;
var i, j, offset: longint;
    color: byte;
    x, y, xi, yi: word;
begin
    graphmode(true, false);
    fillchar(mem[$A000:0], 64000, 0);
    for i := 1 to maxi do begin
        for j := 1 to 1 do begin
            x := (i-1) * 31 mod 256;
            y := (j-1) * 43 mod 200;
            asm
                mov cx, [x]
                mov dx, [y]
                mov al, 21; {blue}
                ;{mov bh, 0; {page number, unnecessary}
                mov ah, 12; {put pixel}
                int 10h
            end;
        end;
        if keypressed then break
    end;
    readln;
    (*for i := 1 to maxi do begin
        for j := 1 to maxj do begin
            x := (i-1) * 31 mod 256;
            y := (j-1) * 43 mod 256;
            for xi := x to x + xdim do
                for yi := y to y + ydim do
                    putpixel(xi, yi, 196);
        end;
        if keypressed then break
    end;
    fillchar(mem[$A000:0], 64000, 0);
    for i := 1 to maxi do begin
        for j := 1 to maxj do begin
            x := (i-1) * 31 mod 256;
            y := (j-1) * 43 mod 200;
            offset := y shl 8 + y shl 6 + x;
            for yi := y to y + ydim do
                fillchar(mem[$A000:offset], xdim, 226);
        end;
        if keypressed then break
    end;*)
    graphmode(false, false);
    readln;
end;

begin
    draw_blocks;
end.
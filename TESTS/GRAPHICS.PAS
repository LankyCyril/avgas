uses crt, graphics;

procedure draw_blocks {
    Tests block drawing:
    * by calling multiple putpixel functions;
      this is the slowest at least because of the function call overhead,
      but also because of the two nested loops;
    * by drawing each vertical line with an assembly loop;
      this is faster, but:
      * requires a lot of 10h interrupts (not sure if it should be slower
        than writing to memory);
      * drawing vertical lines is a-ok, drawing horizontal lines is trickier,
        because the CL register is used for the loop counter as well as
        the x dimension iteration;
      * does not safeguard against getmaxy overrun (not implemented here);
      * setting x or y to negative values does not result in overrun;
        instead, it results in a runtime error (when trying to move to a
        register); this should not be a problem if x and y are not set
        dynamically;
    * by drawing each horizontal line with fillchar;
      this is the fastest method, although it, on the other hand,
      * only makes it simple to draw one horizontal line at a time;
      * still needs getmaxx overrun checks (not implemented here).
    Conclusion:
      * hline() should be implemented with fillchar of memory
        (and getmaxx overrun safeguards added);
      * vline() should be implemented with assembly loops
        (and getmaxy overrun safeguards added: easy to do by truncating
        y2 to getmaxy);
      * wide blocks should be drawn with a loop of memory fillchar;
      * tall blocks may benefit from loops of assembly loops
        (needs to be tested separately).
};
const maxi = 4; maxj = 1024;
      xdim = 12; ydim = 100;
var i, j, offset: longint;
    color: byte;
    x, y, xi, yi: word;
begin
    graphmode(true, false);
    fillchar(mem[$A000:0], 64000, 0);
    for i := 1 to maxi do begin
        for j := 1 to maxj do begin
            x := abs((i-1) * 31 mod 256);
            y := abs((j-1) * 43 mod 256);
            for xi := x to x + xdim do
                for yi := y to y + ydim do
                    putpixel(xi, yi, 196);
        end;
        if keypressed then break
    end;
    fillchar(mem[$A000:0], 64000, 0);
    for i := 1 to maxi do begin
        for j := 1 to maxj do begin
            x := abs((i-1) * 31 mod 256);
            y := abs((j-1) * 43 mod 200);
            for xi := x to x + xdim do asm
                mov cl, [ydim]; {loop counter}
                @@vloop:
                    mov ch, 0; {so we can add cl to dx with `mov dx, cx`}
                    push cx
                    mov dx, [y]
                    add dx, cx; {current vertical offset}
                    mov cx, [xi]
                    mov al, 226; {yellow}
                    ;{mov bh, 0; {page number, unnecessary}
                    mov ah, 12; {put pixel}
                    int 10h
                    pop cx
                    sub cl, 1
                jnz @@vloop
            end;
        end;
        if keypressed then break
    end;
    fillchar(mem[$A000:0], 64000, 0);
    for i := 1 to maxi do begin
        for j := 1 to maxj do begin
            x := abs((i-1) * 31 mod 256);
            y := abs((j-1) * 43 mod 200);
            offset := y shl 8 + y shl 6 + x;
            for yi := y to y + ydim do
                fillchar(mem[$A000:offset], xdim, 46);
        end;
        if keypressed then break
    end;
    graphmode(false, false);
    write('Press <ENTER> to finish block drawing test');
    readln;
end;

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
    writeln;
    write('Press <ENTER> to finish RGB arithmetic test');
    readln;
end;

begin
    draw_blocks;
    rgb_arithmetic;
end.
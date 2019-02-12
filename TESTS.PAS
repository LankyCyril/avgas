uses crt, graphics;

var i, j: longint;
    color, r, g, b: byte;

const maxi = 4; maxj = 65536*128-1;

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
begin
    clrscr;
    for i := 0 to maxi do begin
        for j := 0 to maxj do
            color := rgb[2,3,5];
        write('A');
        if keypressed then break;
    end;
    writeln;
    for i := 0 to maxi do begin
        for j := 0 to maxj do
            color := 2 shl 5 + (2 + 3) shl 2 + 3 shl 1 + 5 + 16;
        write('S');
        if keypressed then break;
    end;
    writeln;
    for i := 0 to maxi do begin
        for j := 0 to maxj do
            color := 2 * 36 + 3 * 6 + 5 + 16;
        write('M');
        if keypressed then break;
    end;
    writeln;
    for i := 0 to maxi do begin
        for j := 0 to maxj do
            color := shl_func(2, 3, 5);
        write('F');
        if keypressed then break;
    end;
end;

begin
    rgb_arithmetic;
end.
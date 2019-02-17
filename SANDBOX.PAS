uses graphics, shapes, palettes;

var x, y: word;

begin
    write('Keep pressing <ENTER>');
    readln;
    graphmode(true);
    for x := 0 to getmaxx do
        for y := 0 to getmaxy do
            putpixel(x, y, rgb[
                x * 16 div (y + 1) mod 5,
                y * 2 div (320 - x) mod 4,
                (x*y) div 200 mod 5
            ]);
    readln;
    resetmask;
    block(32, 14, 286, 184, 15);
    block(33, 15, 285, 183, 0);
    showpalette;
    maskblock(32, 14, 286, 184, true);
    line(310, 99, 10, 99, 15);
    line(159, 0, 159, 199, 15);
    readln;
    for x := 1 to 4 do begin
        fadepalette(0);
        readln;
    end;
    resetcolors;
    readln;
    setpalette(palette.vaporwave);
    readln;
    setpalette(palette.outrun);
    readln;
    for x := 0 to getmaxx do
        for y := 0 to getmaxy do
            mputpixel(x, y, 3);
    readln;
    fillscreen(rgb[2,0,2]);
    readln;
    graphmode(false);
    write('Press <ENTER> to exit');
    readln;
end.

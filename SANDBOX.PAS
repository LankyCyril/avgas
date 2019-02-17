uses graphics, shapes, palettes;

var x, y: word;

begin
    write('Keep pressing <ENTER>');
    readln;
    graphmode(true);
    resetmask;
    block(32, 14, 286, 184, 15);
    block(33, 15, 285, 183, 0);
    showpalette;
    maskblock(32, 14, 286, 184, true);
    line(310, 99, 10, 99, 15);
    line(159, 10, 159, 190, 15);
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
            mputpixel(x, y, rgb[x div 54, y div 29, 0]);
    readln;
    fillscreen(rgb[2,0,2]);
    readln;
    graphmode(false);
    write('Press <ENTER> to exit');
    readln;
end.

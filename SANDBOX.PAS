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
    hline(0, 400, 100, 1);
    write('Showcase default palette');
    readln;
    for x := 1 to 4 do begin
        write('Fade the 216 colors ', x, ' times');
        fadepalette(0);
        readln;
    end;
    resetcolors;
    write('Restore the 216 colors');
    readln;
    setpalette(palette.vaporwave);
    write('Vaporwave palette');
    readln;
    setpalette(palette.outrun);
    write('Outrun palette');
    readln;
    for x := 0 to getmaxx do
        for y := 0 to getmaxy do
            mputpixel(x, y, rgb[x div 54, y div 29, 0]);
    write('mputpixel: avoid masked region');
    readln;
    fillscreen(rgb[2,0,2]);
    write('Fill screen with extended purple');
    readln;
    graphmode(false);
    write('Press <ENTER> to exit');
    readln;
end.

uses graphics, shapes, palettes;

var i: byte;

begin
    write('Keep pressing <ENTER>');
    readln;
    graphmode(true);
    block(32, 14, 286, 184, 15);
    block(33, 15, 285, 183, 0);
    showpalette;
    write('Showcase default palette');
    readln;
    for i := 1 to 4 do begin
        write('Fade the 216 colors ', i, ' times');
        fade(0);
        readln;
    end;
    resetcolors;
    write('Restore the 216 colors');
    readln;
    setpalette(OUTRUN);
    write('Change palette');
    readln;
    fillscreen(rgb[2,0,2]);
    write('Fill screen with extended purple');
    readln;
    graphmode(false);
    write('Press <ENTER> to exit');
    readln;
end.

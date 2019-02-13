uses graphics, shapes;

var r, g, y: byte;
    x: word;

begin
    write('Keep pressing <ENTER>');
    readln;
    graphmode(true);
    for y := 0 to getmaxy do begin
        g := y div 34 mod 6;
        for x := 0 to getmaxx do begin
            r := x div 54;
            putpixel(x, y, rgb[r,g,0]);
        end;
    end;
    getpixel(239, 77, y);
    writeln('Red and green in 6 steps each');
    write('The pixel at (239, 77) is ', y);
    readln;
    for x := 0 to 9 do
        vline(x*30 + 20, 15, 185, 1);
    write('Plot vertical lines with base blue');
    readln;
    for x := 1 to 4 do begin
        write('Fade the 216 colors ', x, ' times');
        fade(0);
        readln;
    end;
    resetcolors;
    write('Restore the 216 colors');
    readln;
    fillscreen(rgb[5,0,5]);
    write('Fill screen with extended pink');
    readln;
    y := 0;
    while hline(y, getmaxx, y, rgb[y div 36 mod 6, 0, y mod 6]) do
        inc(y);
    write('Gradient plot horizontal offset lines');
    readln;
    block(30, 25, 270, 170, 9);
    write('Plot base light blue block');
    readln;
    graphmode(false);
    write('Press <ENTER> to exit');
    readln;
end.

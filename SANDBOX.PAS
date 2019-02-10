uses crt, graphics;

var color: integer;
    r, g, b: byte;

begin
    write('Press <ENTER> to test graphics, <ENTER> again to exit');
    readln;
    graphmode(true);
    for r := 0 to 5 do
        for g := 0 to 5 do
            for b := 0 to 5 do begin
                color := color216(r, g, b);
                putpixel(r+g*6, b, color);
        end;
    putpixel(100, 100, color216(5, 5, 5));
    readln;
    graphmode(false);
end.
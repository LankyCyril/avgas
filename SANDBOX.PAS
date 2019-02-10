uses graphics;

var r, g, b: byte;

begin
    write('Press <ENTER> to test graphics, <ENTER> again to exit');
    readln;
    graphmode(true);
    for r := 0 to 5 do
        for g := 0 to 5 do
            for b := 0 to 5 do begin
                pushrgb(r+g*6, b, r, g, b);
        end;
    readln;
    graphmode(false);
end.
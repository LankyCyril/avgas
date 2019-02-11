uses graphics;

var r, g, b: byte;
    x, y: word;

begin
    write('Press <ENTER> to test graphics, <ENTER> again to exit');
    readln;
    graphmode(true);
    for x := 0 to 300 do begin
        r := x div 50;
        for y := 0 to 199 do begin
            g := y div 40;
            putrgb(x, y, r, g, 0);
        end;
    end;
    readln;
    graphmode(false);
end.
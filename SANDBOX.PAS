uses crt, graphics;

var r, g, b: byte;
    rgb_value: RGB_record;

begin
    write('Press <ENTER> to test graphics, <ENTER> again to exit');
    readln;
    graphmode(true);
    for r := 0 to 5 do
        for g := 0 to 5 do
            for b := 0 to 5 do begin
                putpixel(r+g*6, b, rgb(r, g, b));
        end;
    putpixel(100, 100, rgb(5, 5, 5));
    savergb(34, 3, rgb_value);
    readln;
    graphmode(false);
    writeln(rgb_value.r, ',', rgb_value.g, ',', rgb_value.b);
    readln;
end.
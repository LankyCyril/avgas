uses crt, graphics;

var
    x, y, color: integer;

begin
     write('Press <ENTER> to test graphics, <ENTER> again to exit');
     readln;
     graphmode(true);
     for x := 0 to 319 do begin
         color := x mod 256;
         for y := 0 to 199 do
             putpixel(x, y, color);
     end;
     readln;
     graphmode(false);
end.
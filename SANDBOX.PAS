{$A-,B-,D+,E-,F-,G+,I-,L+,N-,O-,P-,Q-,R+,S-,T-,V+,X+,Y+}
uses graphics, shapes;

var r, g, y: byte;
    x: word;

begin
    write('Keep pressing <ENTER>');
    readln;
    graphmode(true, false);
    for x := 0 to getmaxx do begin
        r := x div 54;
        for y := 0 to getmaxy do begin
            g := y div 40;
            putpixel(x, y, rgb[r,g,0]);
        end;
    end;
    readln;
    getpixel(239, 77, y);
    for x := 1 to 4 do begin
        writeln('Line number ', x);
        fade(0);
        readln;
    end;
    reset_colors;
    readln;
    fillscreen(rgb[5,5,0]);
    readln;
    for y := 0 to getmaxy do
        hline(y, getmaxx, y, 5);
    readln;
    block(30, 30, 270, 150, 1);
    readln;
    graphmode(false, false);
    writeln('The pixel at (239, 77) was ', y);
    write('Press <ENTER> to exit');
    readln;
end.
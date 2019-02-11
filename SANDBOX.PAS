{$A-,B-,D+,E+,F-,G+,I-,L+,N-,O-,P-,Q-,R+,S-,T-,V+,X+,Y+}
uses graphics;

var r, g, y: byte;
    x: word;

begin
    write('Keep pressing <ENTER>');
    readln;
    graphmode(true);
    for x := 0 to getmaxx do begin
        r := x div 54;
        for y := 0 to getmaxy do begin
            g := y div 40;
            putrgb(x, y, r, g, 0);
        end;
    end;
    readln;
    getrgb(239, 77, r, g, y);
    for x := 0 to 3 do begin
        fade(0);
        readln;
    end;
    reset_colors;
    readln;
    graphmode(false);
    writeln('The pixel at (239, 77) was ', r, ',', g, ',', y);
    write('Press <ENTER> to exit');
    readln;
end.
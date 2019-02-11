{$A-,B-,D+,E+,F-,G+,I-,L+,N-,O-,P-,Q-,R+,S-,T-,V+,X+,Y+}
{$M 16384,0,655360}
uses graphics;

var r, g, y: byte;
    x: word;

begin
    write('Press <ENTER> to test graphics, <ENTER> again to exit');
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
    graphmode(false);
    writeln('The pixel at (239, 77) was ', r, ',', g, ',', y);
    write('Press <ENTER> to exit');
    readln;
end.
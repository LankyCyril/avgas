{$A-,B-,D+,E+,F-,G+,I-,L+,N-,O-,P-,Q-,R+,S-,T-,V+,X+,Y+}
{$M 16384,0,655360}
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
    getrgb(239, 77, r, g, b);
    graphmode(false);
    writeln('The pixel at (239, 77) was ', r, ',', g, ',', b);
    write('Press <ENTER> to exit');
    readln;
end.
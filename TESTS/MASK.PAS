uses graphics, shapes;

var y: word;

begin
    graphmode(true);
    resetmask;
    maskblock(100, 100, 200, 150, true);
    maskblock(300, 180, 340, 220,  true);
    for y := 0 to getmaxy do
        line(0, y, getmaxx, y, rgb[5, 4, 0]);
    block(5, 5, getmaxx-5, getmaxy-5, 2);
    readln;
end.

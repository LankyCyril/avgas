UNIT SHAPES;

INTERFACE

function hline(x1, x2, y: word; color: byte): boolean {
    draws a horizontal line from point (x1, y) to point (x2, y) with `color`
};

IMPLEMENTATION

uses graphics;

function hline(x1, x2, y: word; color: byte): boolean {
    Draws a horizontal line from point (x1, y) to point (x2, y) with `color`;
    truncates line appropriately if outside of screen bounds;
    if x1 > x2, or if line completely out of bounds, returns false;
    otherwise returns true.
};
var length: word;
begin
    hline := true;
    if (x1 > x2) or (x1 > getmaxx) or (y > getmaxy) then
        hline := false
    else if x1 <= getmaxx then begin
        if x2 > getmaxx then
            length := getmaxx - x1 + 1
        else
            length := x2 - x1 + 1;
        fillchar(mem[$A000: y shl 8 + y shl 6 + x1], length, color);
    end
    else
        mem[$A000: y shl 8 + y shl 6 + x1] := color;
end;

end.


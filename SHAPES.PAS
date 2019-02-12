UNIT SHAPES;

INTERFACE

function hline(x1, x2, y: word; color: byte): boolean {
    draws a horizontal line from point (x1, y) to point (x2, y) with `color`
};
function vline(x, y1, y2: word; color: byte): boolean {
    draws a vertical line from point (x, y1) to point (x, y2) with `color`
};
function block(x1, y1, x2, y2: word; color: byte): boolean {
    draws a filled rectangle of `color` from point (x1, y1) to point (x2, y2)
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

function vline(x, y1, y2: word; color: byte): boolean {
    Draws a vertical line from point (x, y1) to point (x, y2) with `color`;
    returns false y1 > y2 or if completely out of bounds, true otherwise.
};
var length, yd, startmem: word;
begin
    vline := true;
    if (y1 > y2) or (x > getmaxx) or (y1 > getmaxy) then
        vline := false
    else begin
        if y2 > getmaxy then
            length := getmaxy - y1 + 1
        else
            length := y2 - y1 + 1;
        startmem := y1 shl 8 + y1 shl 6 + x;
        for yd := 0 to length do
            mem[$A000: startmem + yd shl 8 + yd shl 6] := color;
    end;
end;

function block(x1, y1, x2, y2: word; color: byte): boolean {
    Draws a filled rectangle of `color` from point (x1, y1) to point (x2, y2);
    returns false if has negative dimensions or completely out of bounds;
    otherwise, returns true.
};
var y: word;
begin
    block := true;
    if (x1 > x2) or (y1 > y2) or (x1 > getmaxx) or (y1 > getmaxy) then
        block := false
    else for y := y1 to y2 do
        hline(x1, x2, y, color);
end;

end.


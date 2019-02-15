uses graphics;

type tbyte = ^byte;
var bitmaps: tbyte;
    i: byte;

procedure getfonts; assembler;
asm
    push es
    push ds
    cld
    mov  ax, 1130h   {store font bitmaps at [ES:BP]}
    mov  bh, 6
    int  10h
    mov  ax, es
    mov  ds, ax
    mov  si, bp      {point [DS:SI] to VGA bitmaps}
    mov  cx, 256
    @loopyloop:
        lodsb
        mov ah, 2
        mov dl, al
        int 21h
        sub cx, 1
        cmp cx, 0
        ja @loopyloop
    pop  ds
    pop  es
end;

procedure wacky;
var reges, regbp: word;
    i: word;
begin
    asm
        push es
        push bp
        mov ax, 1130h
        mov bh, 6
        int 10h
        mov ax, es
        mov [reges], ax
        mov ax, bp
        mov [regbp], bp
        pop  bp
        pop  es
    end;
    writeln(reges, ':', regbp);
    for i := 0 to 512 do
        write(mem[reges:regbp+i], ', ');
end;

begin
    graphmode(true);
    {wacky;}
    graphmode(false);
    for i := 0 to 255 do
        write(chr(i));
    writeln;
    write('AB:');
    write(chr(8));
    write('_');
    readln;
end.

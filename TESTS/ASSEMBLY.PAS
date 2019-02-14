uses crt;

procedure simple_division(color: word);
var r, g, b: byte;
begin
    asm
        mov ax, [color]
        mov ch, 6
        div ch
        mov [b], ah
        mov ah, 0
        div ch
        mov [g], ah
        mov [r], al
    end;
    writeln(r, ', ', g, ', ', b);
    readln;
end;

procedure iterative_rgb; assembler;
asm
    mov bx, 16; {start with color 16}
    @@paletteloop:
    push bx
    mov ax, bx; {dividend}
    sub ax, 16
    mov dl, 6; {divisor}
    div dl
    mov cl, ah; {move remainder to blue register}
    mov ah, 0; {make sure ax = al, our quotient}
    div dl
    mov ch, ah; {move remainder to green register}
    mov dh, al; {move quotient to red register}
    ; {printing goes here}
    mov ah, 2
    mov dl, dh
    add dl, "0"
    int 21h
    mov ah, 2
    mov dl, ch
    add dl, "0"
    int 21h
    mov ah, 2
    mov dl, cl
    add dl, "0"
    int 21h
    mov ah, 2
    mov dl, 10
    int 21h
    mov ah, 2
    mov dl, 13
    int 21h
    pop bx
    ; {jumping goes here}
    add bx, 1
    cmp bx, 231
    jl @@paletteloop
end;

procedure argswitch(a, b: word);
var t: word;
begin
    t := b;
    b := a;
    a := t;
    writeln(a, ', ', b);
end;

procedure ass_loop; assembler;
asm
end;

function ass_uppercase(str: string): string; assembler;
asm
    push ds; {preserve; used for lds}
    cld; {clear direction flag; string pointers will auto-increment}
    lds si, str; {load pointer using DS, so [ds:si] is pointing to str;
        also see, LEA: load effective address (offset of str);
        LES: load pointer using ES;
    }
    les di, @result; {[es:di] are pointing to @result}
    lodsb; {load byte at [ds:si] into AL; lodsw would load word into AX}
    stosb; {store AL at [es:di]; stosw would store AX}
    mov ah, 0
    xchg ax, cx; {exchange values}
    jcxz @3; {jump short if CX=0, length of string is 0}
  @1:
    lodsb
    cmp al, 'a'
    jb @2; {jump if below; unsigned version of jl}
    cmp al, 'z'
    ja @2; {jump if above; unsigned version of jg}
    sub al, 20h
  @2:
    stosb
    loop @1
  @3:
    pop ds
end;

procedure iter_string(str: string); assembler;
asm
    push ds
    cld
    lds si, str; {make [ds:si] point to `str`}
    lodsb; {load char at [ds:si] into al; 0th char is string length}
    cmp al, 0
    je @terminate
    mov cl, al; {move length of string into loop counter register}
  @iterate:
    lodsb; {load next char (actual char)}
    mov dl, al
    mov al, 0
    mov ah, 2
    int 21h
    loop @iterate
  @terminate:
    pop ds
end;

const a239: array[0..2] of byte = (2, 3, 9);

procedure iter_array(const arr: array of byte; length: byte); assembler;
asm
    push ds
    cld
    lds si, arr; {make [ds:si] point to `arr`}
    cmp [length], 0
    je @terminate
    mov cl, [length]; {move length of array into loop counter register}
  @iterate:
    lodsb; {load next byte from arr}
    mov dl, al
    add dl, '0'
    mov al, 0
    mov ah, 2
    int 21h
    loop @iterate
  @terminate:
    pop ds
end;

begin
    clrscr;
    iter_array(a239, 3);
    readln;
end.
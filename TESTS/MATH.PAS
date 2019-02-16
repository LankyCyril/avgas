uses  crt;

type  arr = array[0..7] of byte;
const A: arr = (10, 20, 30,  5,   2, 3,   7, 8);
      B: arr = (0,  0,  255, 255, 0, 255, 0, 255);
var   i: byte;

procedure array_and(const A, B: arr); assembler;
asm
    push es
    push ds
    cld
    lds  si, B {readable}
    les  di, A {writeable, but also readable}
    mov  cl, 8
    @aloop:
        lodsb
        and  al, [es:di]
        stosb
        sub cl, 1
        jnz @aloop
    pop  ds
    pop  es
end;

begin
    clrscr;
    for i := 0 to 7 do
        write(A[i], ', ');
    writeln;
    array_and(A, B);
    for i := 0 to 7 do
        write(A[i], ', ');
    readln;
end.
# smol
\\(^ n ^)/ a smol cpu hardware and software design based on the <a href='https://en.wikipedia.org/wiki/Hack_computer'>hack computer</a>

# software
## assembler
sw.lisp options:
<pre>
-h help
-g debug on
-data [data section base addr]
asm 
    -print-all-insts 
    -i [input asm file]
    -o [output memh]
bin 
    -o [output binary]
</pre>
for example: 
<pre>
./sw.lisp asm -i test1.asm -o rom.memh bin -o rom.bin 
</pre>
## syntax
### instructions
#### registers
p[15:0] : pc, start from entry, halt when PC==0xffff<br>
i[15:0] : instruction<br>
a[15:0] : from i to addr<br>
d[15:0] <br>
m[15:0] : rdata, signed<br>
#### src
read y input of alu from a or m
#### alu 
constant operators: c0, c1, c-1<br>
prefix unary operators: ^, !, 1+, 1-, -<br>
infix binary operators: &, v, +, -, << <br>
#### dst
write alu output to a, d, m, or nowhere
#### jmp
jeq : jump if alu output ==0<br>
jne : jump if alu output !=0<br>
jgt : jump if alu output >0<br>
jge : jump if alu output >=0<br>
jlt : jump if alu output <0<br>
jle : jump if alu output <=0<br>
jmp : jump <br>
#### example
AD=!A!^<<D?JLE means in one cycle do: <br>
  alu=~(bitflip((~A)<<D)), A=alu, D=alu, if alu<=0 then jump to A 
### program
include file : (inc path)<br>
expand macro : (macroname argvs... )<br>
map : ((char/value "string"/#(vector)) body... )<br>
lambda : ((binds... ) body... )<br>
define macro : (macroname (args... ) body... )<br>
define value : (name bytes)<br>
constant number : number, char <br>
#### example
hellowhorld
<pre>
(inc "init.asm")
(set io_i_a0 (const #x1))
(set io_oe_a0 (const #x1))
(set baud (const 18)) ;; delay for 115200 baudrate in 50MHz clock
((c "hello world!") (tx (const c)))
(quit)
</pre>

# hardware
## simulation
<pre>
iverilog -g2012 -DSIM -DFST hw.sv -s tb
./a.out -fst 
</pre>

## fpga
### quartus
#### EP4CE6E22C8
<pre>
quartus_sh -t EP4CE6E22C8.tcl
quartus_cpf -c EP4CE6E22C8.cof
</pre>


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
<pre>
(const (n) n D=A)
(eval (s) s D=M)
(set (s e) e s M=D)
(+ (a b) a D=M b D=D+M)
(jlt (s e v) e v D=D-A s D?JLT)
(a1 1) (b1 1) (c1 1) 
(((a a1) (b b1) (c c1))  
  (set a (const 1)) (set b (const 1)) (set c (const 1))
  (_loop)
  (set a (eval b)) (set b (eval c))
  (set c (+ a b))
  (jlt _loop (eval c) 80)
)
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

<pre>
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
; Fitter Resource Utilization by Entity                                                                                                                                                                                                                                                                            ;
+----------------------------------------+-------------+---------------------------+---------------+-------------+------+--------------+---------+-----------+------+--------------+--------------+-------------------+------------------+----------------------------------------------------------+--------------+
; Compilation Hierarchy Node             ; Logic Cells ; Dedicated Logic Registers ; I/O Registers ; Memory Bits ; M9Ks ; DSP Elements ; DSP 9x9 ; DSP 18x18 ; Pins ; Virtual Pins ; LUT-Only LCs ; Register-Only LCs ; LUT/Register LCs ; Full Hierarchy Name                                      ; Library Name ;
+----------------------------------------+-------------+---------------------------+---------------+-------------+------+--------------+---------+-----------+------+--------------+--------------+-------------------+------------------+----------------------------------------------------------+--------------+
; |top                                   ; 815 (188)   ; 116 (49)                  ; 0 (0)         ; 4096        ; 1    ; 0            ; 0       ; 0         ; 11   ; 0            ; 699 (145)    ; 23 (10)           ; 93 (26)          ; |top                                                     ; work         ;
;    |altsyncram:ram_rtl_0|              ; 0 (0)       ; 0 (0)                     ; 0 (0)         ; 4096        ; 1    ; 0            ; 0       ; 0         ; 0    ; 0            ; 0 (0)        ; 0 (0)             ; 0 (0)            ; |top|altsyncram:ram_rtl_0                                ; work         ;
;       |altsyncram_llf1:auto_generated| ; 0 (0)       ; 0 (0)                     ; 0 (0)         ; 4096        ; 1    ; 0            ; 0       ; 0         ; 0    ; 0            ; 0 (0)        ; 0 (0)             ; 0 (0)            ; |top|altsyncram:ram_rtl_0|altsyncram_llf1:auto_generated ; work         ;
;    |cpu:cpu|                           ; 640 (640)   ; 67 (67)                   ; 0 (0)         ; 0           ; 0    ; 0            ; 0       ; 0         ; 0    ; 0            ; 554 (554)    ; 13 (13)           ; 73 (73)          ; |top|cpu:cpu                                             ; work         ;
+----------------------------------------+-------------+---------------------------+---------------+-------------+------+--------------+---------+-----------+------+--------------+--------------+-------------------+------------------+----------------------------------------------------------+--------------+

</pre>

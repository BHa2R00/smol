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
#### registors
p[15:0] : pc, start from entry, halt when PC==0xffff
i[15:0] : instruction
a[15:0] : from i to addr
d[15:0] 
m[15:0] : rdata, signed
#### src
read y input of alu from a or m
#### alu 
constant operators: c0, c1, c-1
prefix unary operators: ^, !, 1+, 1-, -
infix binary operators: &, v, +, -, << 
#### dst
write alu output to a, d, m, or nowhere
#### jmp
jeq : jump if alu output ==0
jne : jump if alu output !=0
jgt : jump if alu output >0
jge : jump if alu output >=0
jlt : jump if alu output <0
jle : jump if alu output <=0
jmp : jump 
#### example
AD=!A!^<<D?JLE means: alu=~(bitflip((~A)<<D)), A=alu, D=alu, if alu<=0 then jump to A 
### program
include file : (inc path)
expand macro : (macroname argvs... )
lambda : ((binds... ) body... )
define macro : (macroname (args... ) body... )
define value : (name bytes)
constant number : number 
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

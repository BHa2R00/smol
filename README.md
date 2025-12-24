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
./sw.lisp asm -i test1.asm -o rom.memh 
</pre>

# hardware
## simulation
<pre>
iverilog -g2012 -DSIM -DFST hw.sv -s tb
./a.out -fst 
</pre>

## quartus
### EP4CE6E22C8
<pre>
quartus_sh -t EP4CE6E22C8.tcl
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

# smol
\\(^ n ^)/ a smol cpu hardware and software design

# software
## hw.lisp options:
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

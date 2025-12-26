(inc "init.asm")
(set io_i_a0 D=C1)
(set io_oe_a0 D=C1)
(set baud (const 1)) ;; nop delay for 500kHz Baudrate with 50MHz main clock 
(_loop)
((c "Shit!") (tx (const c))) (tx (const #\Newline)) (tx (const #\Return))
((c "urmom is so FAT") (tx (const c))) (tx (const #\Newline)) (tx (const #\Return))
(_wait) (const #b100) io_c_a0 D=D&M _wait D?JEQ 
_loop D?JMP
;(quit)

(inc "init.asm")
(set io_oe_a0 (const #b1))
(set io_os_a0 (const 0))
(set io_ie_a0 (const #b100))
(set io_is_a0 (const 0))
(set tmr_sel_a0 (const 1))
(set baud (const 58)) ;; timer/from for 115200 baudrate from 25MHz timer clock 
(_loop)
((c "press k1") (putc (const c))) 
(putc (const #\Newline)) (putc (const #\Return))
(_wait) (eval io_c_a0) _wait D?JNE
_loop D?JMP

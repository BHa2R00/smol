(inc "init.asm")
(set io_oe_a0 (const #b1))
(set io_os_a0 (const 0))
(set io_ie_a0 (const #b100))
(set io_is_a0 (const 0))
(set baud (const 26)) ;; delay for 115200 baudrate in 100MHz clock
(_loop)
((c "press k1") (putc (const c))) 
(putc (const #\Newline)) (putc (const #\Return))
(_wait) (eval io_c_a0) _wait D?JNE
_loop D?JMP

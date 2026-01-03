(inc "init.asm")
(set io_oe_a0 (const #b01))
(set io_os_a0 (const 0))
(set io_ie_a0 (const #b10))
(set io_is_a0 (const 1))
(set baud (const 16)) ;; delay for 115200 baudrate in 50MHz clock
(set io_i_a0 (const 1))
(_loop) (putc (getc)) _loop D?JMP

(inc "init.asm")
(main)
(set io_oe_a0 (const #b01))
(set io_os_a0 (const 0))
(set io_ie_a0 (const #b10))
(set io_is_a0 (const -1))
(set tmr_sel_a0 (const 1))
(set baud (const 70)) ;; timer/from for 115200 baudrate from 25MHz timer clock 
(set io_i_a0 (const 1))
(_loop) (putc (getc)) _loop D?JMP 

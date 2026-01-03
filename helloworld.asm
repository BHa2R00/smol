(inc "init.asm")
(set io_i_a0 (const 1))
(set io_oe_a0 (const #b1))
(set io_os_a0 (const 0))
(set baud (const 16)) ;; delay for 115200 baudrate in 50MHz clock
((c "hello world!") (putc (const c))) 
(putc (const #\Newline)) (putc (const #\Return))
(quit)

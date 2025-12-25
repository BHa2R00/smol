(inc "init.asm")

(v1 1) (v2 1) (v3 1) (v4 1) (v5 1) (v6 1)
(set v2 (<< (set v1 (1<< 6)) -3))
(set 
  v4 
  (() 
    (set v3 (0<< 5)) 
    8 D=D^<<A))

(set io_oe_a0 (const #xff))
(((a v4) (b v5) (c v6))
  (set a (const 1)) (set b (const 1)) (set c (const 1))
  (_loop)
  (set a (eval b)) (set b (eval c))
  (set c (+ a b))
  (set io_i_a0 (eval c))
  (jlt _loop (eval c) 80)
)
((v #(1 2 3 4))
((c "shit") (set io_i_a0 c))
 (set io_i_a0 (const v)))
(set baud (const 5))
(set io_i_a0 (const #x1))
(set io_oe_a0 (const #x1))
((c "shit") (set v1 (eval c)) (tx (const c)))

(quit)

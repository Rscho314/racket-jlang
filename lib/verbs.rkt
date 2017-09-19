#lang racket/base

(require (for-syntax racket/base)
         math/array
         math/number-theory
         (only-in racket/list make-list)
         racket/math
         racket/provide
         racket/vector
         "../rank/frame.rkt"
         "../rank/noun.rkt"
         "../rank/verb.rkt")

(define-syntax-rule (define/atomic id proc)
  (define id (atomic-procedure->ranked-procedure proc)))

(define-syntax-rule (define-monad-alias id proc)
  (define/atomic id (procedure-reduce-arity proc 1)))

(define-syntax-rule (define-dyad-alias id proc)
  (define/atomic id (procedure-reduce-arity proc 2)))

; self-classify; equal

(define/rank (j:box y) (array (box y)))

; less-than; lesser-of

(define-monad-alias j:decrement sub1)

; less-than-or-equal

(define/atomic j:open (λ (y) (if (box? y) (unbox y) y)))

; larger-than
; ceiling
; larger-of

(define-monad-alias j:increment add1)

; larger-or-equal

(define-monad-alias j:conjugate conjugate)

(define-dyad-alias j:plus +)

(define/atomic j:real+imaginary (λ (y) (array #[(real-part y) (imag-part y)])))

; GCD [how to apply to complex?]

(define/atomic j:double (λ (y) (* y 2)))

(define/atomic j:not-or (λ (x y) (= 0 x y)))

; signum (complex)

(define-dyad-alias j:times *)

(define/atomic j:length+angle (λ (y) (array #[(magnitude y) (angle y)])))

; lcm

(define/atomic j:square (λ (y) (expt y 2)))

(define/atomic j:not-and (λ (x y) (if (= 1 x y) 0 1)))

(define-monad-alias j:negate -)

(define-dyad-alias j:minus -)

(define/atomic j:not (λ (y) (- 1 y)))

; less

(define/atomic j:halve (λ (y) (/ y 2)))

; match

(define/atomic j:reciprocal (λ (y) (if (zero? y) +inf.0 (/ y))))

(define-dyad-alias j:divided-by /) ; TODO 0/0, complex/0

; matrix inverse
; matrix divide

(define-monad-alias j:square-root sqrt)

(define/atomic j:root (λ (x y) (if (zero? x) +inf.0 (expt y (/ x)))))

(define-monad-alias j:exponential exp)

(define-dyad-alias j:power expt) ; TODO: fit

(define-monad-alias j:natural-log log)

(define/atomic j:logarithm (λ (x y) (/ (log y) (log x))))

(define/rank (j:shape-of y) (noun-shape y))

(define/rank (j:shape [x 1] y)
  ; FIXME: this is wrong
  (array-reshape (->array y) (array->vector (->array x))))

; Sparse: not implemented

; self-reference

; nub

; nub-sieve
; not-equal

(define-monad-alias j:magnitude magnitude)

; residue (non-integer)

(define/rank (j:reverse y) ; TODO: fit (right-shift)
  (if (zero? (noun-rank y))
      y
      (array-slice-ref (->array y) (list (:: #f #f -1) ::...))))

; rotate

(define/rank (j:transpose y)
  (let* ([y (->array y)]
         [r (array-dims y)])
    (array-axis-permute y (build-list r (λ (i) (- (sub1 r) i))))))

; transpose (dyad)

(define/rank (j:ravel y) (array-flatten (->array y)))

; append

; ravel items

; stitch

(define/rank (j:itemize y) (array-axis-insert (->array y) 0))

; laminate

; raze
; link

; words
; sequential machine

(define/rank (j:tally y) (noun-tally y))

; copy

; base two
;base
;antibase two
;antibase
;factorial
;out-of
;grade-up
;sort
;grade-down
;sort

(define/rank (j:same y) y)

(define/rank (j:left x y) x)

(define/rank (j:right x y) y)

;cap
;catalogue
;from
;head
;take
;tail
;map
;fetch
;behead
;drop
;curtail
;do
;numbers
;default-format
;format
;roll
;deal
;roll/fixed
;deal/fixed
;anagram-index
;anagram
;cycle-direct
;permute
;raze-in
;member (in)
;member-of-interval

(define/rank (j:integers [y 1]) ; TODO: fit
  (define shape (array->vector (->array y)))
  (array-slice-ref (index-array (vector-map abs shape))
                   (map (λ (d) (:: #f #f (sgn d))) (vector->list shape))))

;index-of
;indices
;interval-index

(define/atomic j:imaginary (λ (y) (* 0+1i y)))

(define/atomic j:complex (λ (x y) (+ x (* 0+1i y))))

;level-of
;pi-times
;circle-function
;roots
;polynomial
;poly-derive
;poly-integral

(define-monad-alias j:primes nth-prime)

; primes (dyad)

(define/rank (j:prime-factors [y 0])
  (list->array (apply append (map (λ (p) (make-list (cadr p) (car p))) (factorize y)))))

;prime-exponents

(define/atomic j:angle (λ (y) (make-polar 1 y)))

(define-dyad-alias j:polar make-polar)

;symbol
;unicode
;extended precision

(provide (filtered-out
          (λ (name)
            (and (regexp-match? #rx"^j:." name)
                 (substring name 2)))
          (all-defined-out)))
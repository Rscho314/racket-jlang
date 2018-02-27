#lang scribble/manual

@(require scribble/example
          (for-label math/array
                     racket/base
                     racket/contract/base
                     racket/math
                     racket/vector
                     j/rank))

@title{Ranked Apply}

@(define rank-eval (make-base-eval))
@examples[#:hidden #:eval rank-eval (require math/array racket/sequence j/rank)]

@defmodule[j/rank]{
  Support for J-style ranked apply.
}

@section{Ranked Values}

@subsection{Definitions3}

@defproc[(atom? [v any/c]) boolean?]{
  Equivalent to @racket[(zero? (rank v))].
}

@defproc[(normalized-value? [v any/c]) boolean?]{
  A normalized value has one of the following forms:
  @itemize[
    @item{an @racket[array?] with nonzero dimension;}
    @item{an @racket[array?] with zero dimension whose element is not a @racket[normalized-value?];}
    @item{an exact nonnegative integer; or}
    @item{anything which is not an @racket[array?] or a @racket[sequence?].}
  ]
}

@defproc[(normalize-value [v any/c]) normalized-value?]{
  Produces a normalized form of @racket[v].
}

@defproc[(->array [v any/c]) array?]{
  Coerces @racket[v] to an array. In particular, lists, vectors and sequences
  (but not exact nonnegative integers) are converted to a one-dimensional
  array containing their elements. Note that strings are interpreted as sequences.

  @examples[#:eval rank-eval
            (->array '(1 2 3))
            (->array (vector 5))
            (->array "hello")
            (->array 'sym)
            (->array (array #[#[0 1] #[2 3]]))
            (->array (array "atomic string"))]
}

@defproc[(sequence->array [s sequence?]) array?]{
  Returns a one-dimensional array containing the elements of @racket[s].
}

@defproc[(rank [v any/c]) exact-nonnegative-integer?]{
  Returns the rank of @racket[v].

  @examples[#:eval rank-eval
            (rank 3)
            (rank '(3))
            (rank (index-array #[2 3 4]))
            (rank (vector))]
}

@defproc[(shape [v any/c]) (vectorof exact-nonnegative-integer?)]{
  Returns the shape of @racket[v].

  Examples:
  @examples[#:eval rank-eval
            (shape 3)
            (shape '(3))
            (shape (index-array #[2 3 4]))
            (shape (vector))]
}

@defproc[(ranked-value [atom/c flat-contract?]) flat-contract?]{
  Returns a contract that requires the input to be a value with
  atoms matching @racket[atom/c].
}

@section{Items}

@subsection{Definitions1}

@defproc[(item-count [v any/c]) exact-nonnegative-integer?]{
  Returns the number of items in @racket[v].

  Examples:
  @examples[#:eval rank-eval
            (item-count 3)
            (item-count '(3))
            (item-count (index-array #[2 3 4]))
            (item-count (vector))]
}

@defproc[(item-ref [v any/c] [pos (ranked-value exact-integer?)]) any/c]{
  Returns the item of @racket[v] at position @racket[pos], where the first
  item is position @racket[0], and negative positions count backwards from
  the end.
}

@defproc[(item-shape [v any/c]) (vectorof exact-nonnegative-integer?)]{
  Returns the shape of an item of @racket[v].
  Equivalent to @racket[(if (atom? v) #[] (vector-drop (shape v) 1))].
}

@defproc[(head-item [v any/c]) any/c]{
  Returns the first item of @racket[v].
  Equivalent to @racket[(item-ref (take-items v 1) 0)].
}

@defproc[(last-item [v any/c]) any/c]{
  Returns the last item of @racket[v].
  Equivalent to @racket[(item-ref (take-items v -1) 0)].
}

@defproc[(take-items [v any/c] [pos (ranked-value (or/c exact-integer? infinite?))]) any/c]{
  Returns the first @racket[pos] items of @racket[v] if @racket[pos] is atomic
  (counting from the end if @racket[pos] is negative). If @racket[pos] is a
  vector, this process is applied recursively to the items returned according
  to the succesive elements of @racket[pos].

  If more items are requested than are contained in @racket[v], the extra items
  will be filled with @racket[(current-fill)].
}

@defproc[(tail-items [v any/c]) any/c]{
  Returns all the items of @racket[v] except the first.
  Equivalent to @racket[(drop-items v 1)].
}

@defproc[(drop-items [v any/c] [pos (ranked-value (or/c exact-integer? infinite?))]) any/c]{
  Drops the first @racket[pos] items of @racket[v] if @racket[pos] is atomic
  (counting from the end if @racket[pos] is negative). If @racket[pos] is a
  vector, this process is applied recursively to the items returned according
  to the succesive elements of @racket[pos].
}

@defproc[(reshape-items [v any/c] [new-shape (ranked-value exact-nonnegative-integer?)]) any/c]{
  Reshape the items of @racket[v]. The returned value will have the shape
  @racket[(vector-append new-shape (item-shape v))], with the same items
  as @racket[v], repeating or truncating if necessary.
}

@defproc[(in-items [v any/c]) sequence?]{
  Returns a sequence consisting of the items of @racket[v].

  @examples[#:eval rank-eval
            (sequence->list (in-items 3))
            (sequence->list (in-items '(3)))
            (sequence->list (in-items (index-array #[2 3 4])))
            (sequence->list (in-items (vector)))]
}

@section{Ranked Procedures}

@subsection{Definitions2}

A ranked procedure implicitly iterates over its arguments according to its rank.

@examples[#:eval rank-eval
          (apply/rank + (list '(100 200) (index-array '#[2 3])))
          (define isnum? (atomic-procedure->ranked-procedure char-numeric?))
          (procedure-rank isnum? 1)
          (isnum? #\4)
          (isnum? "abc123")
          (define/rank (sum-rows [y 1]) (if (atom? y) y (apply + (array->list y))))
          (sum-rows (array #[#[1 3 5] #[2 4 6]]))
          (sum-rows '(5 10 15))
          (sum-rows 11)
          (define/rank (replace-items [x #f] [y -1]) x)
          (replace-items '(one two) (array #[1 2 3]))
          (define/rank (integers [y 1]) (index-array (array->vector (->array y))))
          (apply/rank integers (list (array #[#[2 2] #[3 3]])) #:fill 9)]

@defthing[procedure-rank/c contract?]{
  Equivalent to @racket[(listof (or/c exact-integer? #f))].
}

@defthing[rankable-procedure/c contract?]{
  A contract which accepts procedures that have no required keyword arguments
  and return a single value.
}

@defproc[(ranked-procedure? [v any/c]) boolean?]{
  Returns @racket[#t] if @racket[v] is a ranked procedure, @racket[#f] otherwise.
}

@defparam[current-fill fill any/c
          #:value #f]{
  A parameter that defines the value to be used for padding cells.
}

@defproc[(apply/rank [proc (or/c procedure? ranked-procedure?)]
                     [v any/c] ...
                     [lst list?]
                     [#:fill fill any/c (current-fill)])
         normalized-value?]{
  Similar to the ordinary Racket @racket[apply], except that non-ranked procedures
  are assumed to have rank @racket[0] for each argument.

  If the results of @racket[proc] have different shapes, then they will be padded
  with @racket[fill].
}

@defproc[(make-ranked-procedure [proc rankable-procedure/c]
                                [rank-spec (or/c (listof procedure-rank/c)
                                                 (-> exact-positive-integer?
                                                     procedure-rank/c))])
         ranked-procedure?]{
  Create a ranked procedure from @racket[proc], with ranks determined by @racket[rank-spec].

  If @racket[rank-spec] is a list, it must contain as many items as @racket[proc] has
  arities, with each item being the same length as the number of arguments accepted.
  Otherwise, @racket[rank-spec] must be a procedure accepting one argument @var{arity},
  and must return a list of that length.
}

@defproc[(atomic-procedure->ranked-procedure [proc rankable-procedure/c])
         ranked-procedure?]{
  Converts @racket[proc] to a ranked procedure with rank @racket[0] for each argument.
}

@defproc[(procedure-rank [proc (or/c procedure? ranked-procedure?)]
                         [arity exact-positive-integer?])
         procedure-rank/c]{
  Returns the rank of @racket[proc] when applied with @racket[arity] arguments.
}

@defform[#:id lambda/rank (lambda/rank (arg ...) body ...+)
         #:grammar
         [(arg id [id rank])]]{
  Creates a ranked procedure. If @racket[rank] is not specified, it defaults
  to @racket[#f] (infinite).
}

@defform[#:id case-lambda/rank(case-lambda/rank [(arg ...) body ...+] ...)
         #:grammar
         [(arg id [id rank])]]{
  Creates a ranked procedure with multiple arities, similar to @racket[case-lambda].
  If @racket[rank] is not specified, it defaults to @racket[#f] (infinite).
}

@defform[#:id define/rank(define/rank (id arg ...) body ...+)]{
  Shorthand for defining ranked procedures.
}

@defthing[prop:rank struct-type-property?]{
  A structure type property to provide the rank of structure types whose instances
  can be applied as procedures.

  The @racket[prop:rank] property value must be a procedure which accepts two arguments.
  The instance is passed as the first argument, and the second is the arity for which
  a rank is required. The procedure must return a value accepted by
  @racket[procedure-rank/c] and of length equal to the arity.
}

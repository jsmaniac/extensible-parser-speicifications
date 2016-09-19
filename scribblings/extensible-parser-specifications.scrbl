#lang scribble/manual
@require[scribble/example
         @for-label[phc-toolkit/untyped
                    extensible-parser-specifications
                    generic-syntax-expanders
                    racket/base
                    syntax/parse
                    (only-in racket/base [... …])]]

@(define make-evaluator
   (make-eval-factory '(syntax/parse
                        extensible-parser-specifications)))

@title{extensible-parser-specifications}
@author{@author+email["Georges Dupéron" "georges.duperon@gmail.com"]}

@(define ntax-pattern (tech #:doc '(lib "syntax/scribblings/syntax.scrbl")
                            #:key "syntax pattern"
                            "syntax-pattern"))

@(define -alternative-mixin (tech #:key "eh-alternative mixin"
                                  "eh-alternative-mixin"))

@(define tribute-name (tech #:doc '(lib "syntax/scribblings/syntax.scrbl")
                            #:key "attribute"
                            "attribute-name"))

@(define A-patte (tech #:doc '(lib "syntax/scribblings/syntax.scrbl")
                       #:key "action pattern"
                       "A-pattern"))

@defmodule[extensible-parser-specifications]

@defform[#:literals (pattern)
         (define-eh-alternative-mixin name maybe-define-class
           (pattern clause-or-mixin) ...)
         #:grammar
         [(maybe-define-class
           (code:line #:define-splicing-syntax-class splicing-name))
          (clause-or-mixin #,ntax-pattern
                           (~mixin #,-alternative-mixin)
                           (~or clause-or-mixin ...)
                           derived-or)]]{
 Defines an @deftech{eh-alternative mixin}, which is implemented as an @tech{
  eh-mixin expander}. An eh-alternative mixin is like an
 @tech[#:doc '(lib "syntax/scribblings/syntax.scrbl")]{ellipsis-head alternative
  set}, except that it can only appear as part of a @racket[~no-order] (possibly
 nested under other eh-alternative mixins), and can contain some global
 constraints. The global constraints, detailed below, allow the parser to
 perform checks across two or more mixins. For example, given a set of options
 that can appear in any order, it is possible to specify that two of them are
 mutually exclusive, or that two other must appear in a certain order,
 regardless of the order of the other options.

 The @racket[derived-or] term covers any
 @tech[#:doc '(lib "syntax/scribblings/syntax.scrbl")]{pattern expander} or
 @tech{eh-mixin expander} application which expands to a
 @racket[clause-or-mixin].}

@deftogether[[@defthing[#:kind "for-syntax value"
                        eh-mixin-expander-type expander-type?]
              @defproc[#:kind "for-syntax procedure"
                       (make-eh-mixin-expander)
                       (and/c expander? eh-mixin-expander?)]
              @defproc[#:kind "for-syntax procedure"
                       (eh-mixin-expander? [v any/c])
                       boolean?]
              @defform[(define-eh-mixin-expander id transformer-procedure)]
              @defproc[#:kind "for-syntax procedure"
                       (expand-all-eh-mixin-expanders [stx-tree syntax?])
                       syntax?]]]{
 These functions and forms allow the creation and manipulation of @deftech{
  eh-mixin expanders}. These identifiers are generated by
 @racket[define-expander-type]. For more information, see the documentation for
 @racket[define-expander-type].}

@section{Pattern expanders and eh-mixin expanders}

@defform[#:kind "pattern expander"
         #:literals (~mixin ~or)
         (~seq-no-order clause-or-mixin ...)
         #:grammar
         [(clause-or-mixin #,ntax-pattern
                           (~mixin #,-alternative-mixin)
                           (~or clause-or-mixin ...)
                           derived-or)]]{
 Splicing pattern which matches the given @racket[clause-or-mixin]s in any
 order, enforcing the global constraints expressed within each.

 Nested @racket[~or] directly below @racket[~seq-no-order] are recursively
 inlined. In other words, the @racket[~or] present directly below the
 @racket[~seq-no-order] or below such an @racket[~or] clause do not behave as
 "exclusive or", but instead contain clauses which can appear in any order.
 These clauses are not grouped in any way by the @racket[~or], i.e.
 @racket[(~no-order (~or (~or a b) (~or c d)))] is equivalent to
 @racket[(~no-order a b c d)].
                                         
 The @racket[derived-or] term covers any
 @tech[#:doc '(lib "syntax/scribblings/syntax.scrbl")]{pattern expander} or
 @tech{eh-mixin expander} application which expands to a
 @racket[clause-or-mixin]. The expansion of pattern and eh-mixin expanders
 happens before inlining the top @racket[~or] clauses.}

@defform[#:kind "pattern expander"
         #:literals (~mixin ~or)
         (~no-order clause-or-mixin ...)
         #:grammar
         [(clause-or-mixin #,ntax-pattern
                           (~mixin #,-alternative-mixin)
                           (~or clause-or-mixin ...)
                           derived-or)]]{
                                         
 Like @racket[~seq-no-order], except that it matches a syntax list, instead of
 being spliced into the surrounding sequence of patterns. In other words,

 @racketblock[(~seq-no-order clause-or-mixin ...)]
 
 Equivalent to (notice the extra pair of braces):

 @racketblock[({~seq-no-order clause-or-mixin ...})]}

@defform[#:kind "eh-mixin expander"
         (~order-point point-name #,ntax-pattern ...)]{
 When parsing a sequence of elements, @racket[~seq-no-order] and
 @racket[~no-order] associate an increasing number to each element starting from
 zero.
 
 The number associated with the first element matched by
 @racket[#,ntax-pattern ...] is memorised into the attribute
 @racket[point-name].

 This allows the position of elements matched by otherwise independent mixins to
 be compared using @racket[order-point<] and @racket[order-point>]}

@defform[(order-point< a b)
         #:grammar
         [(a #,tribute-name)
          (b #,tribute-name)]]{
                          
 Returns @racket[#t] when the first element matched by
 @racket[(~order-point a #,ntax-pattern ...)] occurs before the first element
 matched by @racket[(~order-point b #,ntax-pattern ...)]. Otherwise, returns
 @racket[#f].}

@defform[(order-point> a b)
         #:grammar
         [(a #,tribute-name)
          (b #,tribute-name)]]{
                          
 Returns @racket[#t] when the first element matched by
 @racket[(~order-point a #,ntax-pattern ...)] occurs after the first element
 matched by @racket[(~order-point b #,ntax-pattern ...)]. Otherwise, returns
 @racket[#f].}

@defform[(~mixin #,-alternative-mixin)]{
                                        
 Expands the @racket[#,-alternative-mixin], with no arguments. This is
 equivalent to @racket[(_eh-alternative-mixin)], but @racket[~mixin]
 additionally checks that the given @racket[_eh-alternative-mixin] is indeed an
 @tech{eh-alternative mixin}. Otherwise, with the syntax,
 @racket[(_eh-alternative-mixin)] the name @racket[_eh-alternative-mixin] would
 be interpreted as a pattern variable by @racket[syntax-parse] if the expander
 was not available for some reason (e.g. a missing import).}

@defform[#:kind "pattern expander"
         {~nop}]{
 The @tech[#:doc '(lib "syntax/scribblings/syntax.scrbl")
           #:key "action pattern"]{A-pattern} @racket[~nop] does not perform any
 action. It simply expands to @racket[{~do}].
}

@section{Post operations and global operations}

@subsection{Post operations}

@defform*[[(~post-check #,ntax-pattern #,A-patte)
           (~post-check #,A-patte)]]{
 Matches @racket[#,ntax-pattern], and executes the given @racket[#,A-patte]
 after the whole @racket[~seq-no-order] or @racket[~no-order] finished matching
 its contents.
 
 If unspecified, the @racket[_syntax-pattern] defaults to @racket[(~nop)].}

@defform*[[(~post-fail message #:when condition)
           (~post-fail #:when condition message)
           (~post-fail message #:unless unless-condition)
           (~post-fail #:unless unless-condition message)]]{
                                                   
 After the whole @racket[~seq-no-order] or @racket[~no-order] finished matching
 its contents, checks whether @racket[condition] or @racket[unless-condition] is
 true or false, respectively.  If this is the case the whole
 @racket[~seq-no-order] or @racket[~no-order] is rejected with the given
 @racket[_message].

 Note that there is an implicit cut (@racket[~!]) between the no-order patterns
 and the "post" checks, so after a @racket[~post-fail] fails,
 @racket[syntax-parse] does not backtrack and attempt different combinations of
 patterns to match the sequence, nor does it backtrack and attempt to match a
 shorter sequence. This is by design, as it allows for better error messages
 (syntax-parse would otherwise attempt and possibly succeed in matching a
 shorter sequence, then just treat the remaining terms as "unexpected terms").}

@subsection{Global operations}

The global patterns presented below match all of the given
@racket[#,ntax-pattern]s, like @racket[~and] does, and perform a global
aggregation over all the values corresponding to successful matches of a global
pattern using the same @racket[#,tribute-name].

After the whole @racket[~seq-no-order] or @racket[~no-order] finished matching
its contents, but before "post" operations are executed, the attribute
@racket[#,tribute-name] is bound to
@racket[(_aggrgate-function _value₁ ... _valueₙ)], where each @racket[valueᵢ] is
the value which was passed to an occurrence of @racket[~global-or] with the same
@racket[_attribute-name], and which successfully matched. The
@racket[_aggregate-function] will be @racket[or] for @racket[~global-or],
@racket[and] for @racket[~global-and] or @racket[+] for
@racket[~global-counter].

Each @racket[valueᵢ] is computed in the context in which it appears, after the
@racket[_syntax-pattern]s. This means that it can access:
@itemlist[
 @item{attributes already bound in the current alternative clause within the
  current @racket[~no-order] or @racket[~seq-no-order]}
 @item{attributes bound by the @racket[_syntax-patterns]s}
 @item{attributes already bound outside of the @racket[~no-order] or
  @racket[~seq-no-order]}
 @item{but it cannot access attributes bound in other alternative clauses within
  the current @racket[~no-order] or @racket[~seq-no-order].}]

The @racket[valueᵢ] are aggregated with @racket[or], @racket[and] or @racket[+]
in the order in which they appear in the @racket[~no-order] or
@racket[~seq-no-order]. If a @racket[valueᵢ] appears under ellipses, or as part
of an alternative clause which can match more than once (i.e. not @racket[~once]
or @racket[~optional]), then each match within that @racket[valueᵢ] group is
aggregated in the order it appears.

Since this notion of order is rather complex, it is possible that future
versions of this library will always return a boolean (@racket[#f] or
@racket[#t] for @racket[~global-or] and @racket[~global-and], which would make
the notion of order irrelevant.

@defform[(~global-or attribute-name+value #,ntax-pattern ...)
         #:grammar
         [(attribute-name+value #,tribute-name
                                [#,tribute-name valueᵢ])]]{
 Matches all of the given @racket[#,ntax-pattern]s, like @racket[~and] does, and
 perform a global @racket[or] over all the values corresponding to successful
 matches of a global pattern using the same @racket[#,tribute-name]. See above
 for a description of how global operations work.
                                                     
 If the @racket[valueᵢ] is omitted, @racket[#t] is used as a default.

 Since the aggregation function is @racket[or], the order in which values are
 aggregated means that within each @racket[valueᵢ] group, the first
 non-@racket[#f] value with a successful match of the corresponding
 @racket[_syntax-pattern]s is used. The first @racket[valueᵢ] for which that
 result is not @racket[#f], and with at least one successful match is then used.

 For example, the following code produces @racket['ya]:
 
 @racketblock[
 (syntax-parse #'(1 ya (2 #f 3) 4 yb (5 #f 6) yc 7)
   [(~no-order {~and x:id {~global-or [g (syntax-e #'x)]}}
               {~global-or [g (syntax-e #'y)] y:number}
               ({~global-or [g (syntax-e #'z)] (~and z (~or :number #f))}
                …)
               {~global-or [g (syntax-e #'w)] w:str})
    (attribute g)])]

 This is because the following call to @racket[or] is executed:

 @racketblock[
 (or 'ya 'yb 'yc   (code:comment "matches for x")
     1 4 7         (code:comment "matches for y")
     2 #f 3 4 #f 6 (code:comment "matches for z")
     (code:comment "no matches for w"))]
}

@defform[(~global-and attribute-name+value #,ntax-pattern ...)
         #:grammar
         [(attribute-name+value [#,tribute-name valueᵢ])]]{
 Matches all of the given @racket[#,ntax-pattern]s, like @racket[~and] does, and
 perform a global @racket[and] over all the values corresponding to successful
 matches of a global pattern using the same @racket[#,tribute-name]. See above
 for a description of how global operations work.
                                                     
 Since the aggregation function is @racket[or], the order in which values are
 aggregated means that within each @racket[valueᵢ] group, the last value with a
 successful match of the corresponding @racket[_syntax-pattern]s is used. The
 last @racket[valueᵢ] with at least one successful match is then used. If any
 value within any @racket[valueᵢ] group is @racket[#f], then the
 @racket[_attribute-name] is bound to @racket[#f].
 
 @examples[
 #:eval (make-evaluator)
 #:once
 #:label "For example, the following code produces 6:"
 (syntax-parse #'(1 ya (2 3) 4 yb (5 6) yc 7)
   [(~no-order {~and x:id {~global-and [g (syntax-e #'x)]}}
               {~global-and [g (syntax-e #'y)] y:number}
               ({~global-and [g (syntax-e #'z)] (~and z :number)}
                …)
               {~global-and [g (syntax-e #'w)] w:str})
    (attribute g)])]

 This is because the following call to @racket[or] is executed:

 @racketblock[
 (and 'ya 'yb 'yc   (code:comment "matches for x")
      1 4 7         (code:comment "matches for y")
      2 3 4 6       (code:comment "matches for z")
      (code:comment "no matches for w"))]

 This @tech{eh-mixin expander} is intended to be used to aggregate boolean
 values, so the order in which matches are taken into account should not be
 significant. To perform checks on the order in which matches appear within a
 @racket[~no-order] or @racket[~seq-no-order], see @racket[~order-point],
 @racket[order-point<] and @racket[order-point>].}

@defform[(~global-counter attribute-name+value #,ntax-pattern ...)
         #:grammar
         [(attribute-name+value #,tribute-name
                                [#,tribute-name valueᵢ])]]{
 Matches all of the given @racket[#,ntax-pattern]s, like @racket[~and] does, and
 perform a global @racket[+] over all the values corresponding to successful
 matches of a global pattern using the same @racket[#,tribute-name]. See above
 for a description of how global operations work.

 If the @racket[valueᵢ] is omitted, @racket[1] is used as a default.}

@;@defform[(aggregate-global-or)]
@;@defform[(aggregate-global-and)]
@;@defform[(aggregate-global-counter)]

@subsection{Order in which the attributes are bound for post operations and
 global operations}

Within the @racket[_A-pattern]s of post operations, the regular attributes bound
by all the clauses inside @racket[~seq-no-order] or @racket[~no-order] are
bound. The attributes defined as part of all "global" actions are bound too. The
attributes defined as part of "post" actions of other clauses are bound only if
the clause defining them appears before the current clause in the source code.
For example, the following code works because the clause containing
@racket[{~post-fail "2 is incompatible with 1" #:when (not (attribute a))}]
appears after the clause which binds @racket[a] with the "post" action
@racket[{~post-check {~bind ([a #'the-a])}}].

@racketblock[
 {~seq-no-order
  {~post-check {~and the-a 1} {~bind ([a #'the-a])}}
  {~and 2 {~post-fail "2 is incompatible with 1" #:when (not (attribute a))}}}]

If the two clauses are swapped, then the following code would raise a syntax
error because @racket[a] is not bound as an attribute in the
@racket[~post-fail]:

@racketblock[
 {~seq-no-order
  {~and 2 {~post-fail "2 is incompatible with 1" #:when (not (attribute a))}}
  {~post-check {~and the-a 1} {~bind ([a #'the-a])}}}]

On the other hand, the following code, which does not bind @racket[a] as part
of a post operation, is valid:
 
@racketblock[
 {~seq-no-order
  {~and 2 {~post-fail "2 is incompatible with 1" #:when (not (attribute a))}}
  {~and the-a 1 {~bind ([a #'the-a])}}}]

Furthermore, the following code still works, as attributes are bound by the
"global" operations before the "post" operations are executed:

@racketblock[
 {~seq-no-order
  {~and 2 {~post-fail "2 is incompatible with 1" #:when (not (attribute a))}}
  {~global-or a 1}}]

Note that the order in which clauses appear within the @racket[~seq-no-order]
or @racket[~no-order] does not impact the order in which the elements must
appear in the matched syntax (aside from issues related to greediness).

@defform[(try-attribute #,tribute-name)]{
 This macro expands to @racket[(attribute #,tribute-name)] if
 @racket[#,tribute-name] is bound as a syntax pattern variable, and to
 @racket[#f] otherwise.

 This macro can be used to check for mutual exclusion of an attribute which is
 bound by other mixins that might or might not be present in the final
 @racket[~no-order] or @racket[~seq-no-order].
 
 Use this sparingly, as if an syntax pattern variable with that name is bound by
 an outer scope, the @racket[try-attribute] macro will still access it, ignorant
 of the fact that the current @racket[~seq-no-order] does not contain any mixin
 which binds that attribute.

 Instead, it is better practice to use
 @racket[{~global-or [_attribute-name #f]}] or
 @racket[{~global-and [_attribute-name #t]}] to ensure that the attribute is
 declared, while using the operation's neutral element to not alter the final
 result.}

@defform[(~named-seq #,tribute-name #,ntax-pattern ...)]{
 Equivalent to @racket[{~seq #,ntax-pattern ...}], but also binds the
 @racket[#,tribute-name] to the whole sequence. If the sequence appears inside
 an @racket[~optional] or @racket[~or] clause that fails, the
 @racket[_attribute-name] is still bound to the empty sequence.

 Known issues: this may not behave as expected if @racket[~named-seq] appears
 under ellipses.
 
 This probably should bind the sequence attribute @emph{before} the "global"
 operations, instead of being a "post" operation, and may be changed in that way
 the future.}

@defform[(~optional/else #,ntax-pattern
                         maybe-defaults
                         else-post-fail ...
                         maybe-name)
         #:grammar
         [(maybe-defaults (code:line)
                          (code:line #:defaults (default-binding ...)))
          (else-post-fail
           (code:line #:else-post-fail message #:when condition)
           (code:line #:else-post-fail #:when condition message)
           (code:line #:else-post-fail message #:unless unless-condition)
           (code:line #:else-post-fail #:unless unless-condition message))
          (maybe-name (code:line)
                      (code:line #:name #,tribute-name))]]{
                                                           
 Like @racket[~optional], but with conditional post-failures when the pattern is
 not matched. An @racket[~optional/else] pattern can be matched zero or one time
 as part of the @racket[~seq-no-order] or @racket[~no-order]. When it is not
 matched (i.e. matched zero times):
 @itemlist[
 @item{it uses the default values for the attributes as specified with
   @racket[#:defaults].}
 @item{for each @racket[#:else-post-fail] clause, it checks whether the
   @racket[condition] or @racket[unless-condition] is true or false,
   respectively. If this is the case the whole @racket[~seq-no-order] or
   @racket[~no-order] is rejected with the given @racket[_message]. The
   behaviour of @racket[#:else-post-fail] is the same as the behaviour of
   @racket[~post-fail], except that the "post" conditional failure can only be
   executed if the optional @racket[_syntax-pattern] was not matched.

   Note that there is an implicit cut (@racket[~!]) between the no-order
   patterns and the "post" checks, so after a @racket[~post-fail] fails,
   @racket[syntax-parse] does not backtrack and attempt different combinations
   of patterns to match the sequence, nor does it backtrack and attempt to match
   a shorter sequence. This is by design, as it allows for better error messages
   (syntax-parse would otherwise attempt and possibly succeed in matching a
   shorter sequence, then just treat the remaining terms as
   "unexpected terms").}]

 The meaning of @racket[#:name #,tribute-name] option is the same as for
 @racket[~optional].}


@section{Chaining macro calls without re-parsing everything}

@defform[(define/syntax-parse+simple (name-or-curry . #,ntax-pattern) . body)
         #:grammar
         [(name-or-curry name
                         (name-or-curry arg ...))
          (maybe-define-class #:define-splicing-syntax-class class-id)
          (name identifier?)
          (class-id identifier?)]]{
 This macro works like @racket[define/syntax-parse] from @racket[phc-toolkit],
 except that it also defines the function @racket[_name-forward-attributes],
 which can be used by other macros to forward already parsed attributes to the
 @racket[body], without the need to parse everything a second time.

 The syntax pattern for the @racket[name] macro's arguments can be saved in a
 syntax class by specifying the @racket[#:define-splicing-syntax-class] option.

 If the caller macro which uses @racket[(_name-forward-attributes)] parsed its
 own @racket[stx] argument using @racket[class-id], then
 @racket[(_name-forward-attributes)] is equivalent to expanding
 @racket[(name stx)].

 The @racket[_name-forward-attributes] function is defined at the same meta
 level as @racket[name], i.e. at the same meta-level where this library was
 required. }


@defform[#:kind "for-template syntax"
         (define-syntax/parse+simple (name . #,ntax-pattern) . body)]{
 This macro is provided for meta-level -1.

 This is the same as @racket[define/syntax-parse+simple], except that it
 operates at level -1 relative to this library, and defines at that level a
 transformer binding (which therefore executes at the same meta-level as this
 library. In other words,
 @racket[(define-syntax/parse+simple (name . pat) . body)] is roughly equivalent
 to:

 @racketblock[
 (begin-for-syntax
   (define/syntax-parse+simple (tmp . pat) . body)
   (define name-forward-attributes tmp-forward-attributes))
 (define-syntax name tmp)]}


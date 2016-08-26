#lang racket

(require racket/require
         syntax/parse
         (subtract-in syntax/stx phc-toolkit/untyped)
         rackunit
         racket/format
         phc-toolkit/untyped
         "structure-options2b.rkt"
         (for-syntax syntax/parse
                     syntax/stx
                     racket/format))

(provide structure-kw-instance-or-builder-mixin
         structure-kw-predicate-mixin
         structure-kw-fields-mixin
         structure-kw-all-mixin)

(define-eh-alternative-mixin structure-kw-instance-or-builder
  (pattern (~optional (~and instance-or-builder
                            (~or (~and instance #:instance)
                                 (~and builder #:builder)))
                      #:name "either #:instance or #:builder")))

(define-eh-alternative-mixin structure-kw-predicate
  (pattern (~optional (~seq #:? predicate:id)
                      #:name "#:? predicate")))

(define-and-for-syntax no-values-err
  (~a "The #:instance keyword implies the use of [field value],"
      " [field : type value] or [field value : type]."))

(define-and-for-syntax values-err
  (~a "The #:builder keyword implies the use of [field], field"
      " or [field : type]."))

(define-and-for-syntax empty-err
  (~a "If no fields are specified, then either #:builder or #:instance"
      " must be present"))

(define-eh-alternative-mixin structure-kw-fields
  (pattern
   (~optional/else
    (~or (~seq (~or-bug [field:id] field:id) …+
               (~post-fail no-values-err #:when (attribute instance)))
         (~seq [field:id : type] …+
               (~post-fail no-values-err #:when (attribute instance)))
         (~seq [field:id value:expr] …+
               (~post-fail values-err #:when (attribute builder)))
         (~seq (~or-bug [field:id value:expr : type]
                        [field:id : type value:expr])
               …+
               (~post-fail values-err #:when (attribute builder))))
    #:defaults ([(field 1) (list)]
                [(value 1) (list)]
                [(type 1) (list)])
    #:else-post-fail empty-err #:when (and (not (attribute builder))
                                           (not (attribute instance)))
    #:name (~a "field or [field] or [field : type] for #:builder,"
               " [field value] or [field : type value]"
               " or [field value : type] for #:instance"))))

(define-eh-alternative-mixin structure-kw-all
  (pattern (~or (structure-kw-instance-or-builder-mixin)
                (structure-kw-predicate-mixin)
                (structure-kw-fields-mixin))))

;; ---------

(define-splicing-syntax-class structure-kws
  (pattern (~no-order (structure-kw-all-mixin))))

(check-equal? (syntax->datum
               (syntax-parse #'(#:instance #:? p)
                 [(:structure-kws)
                  #'(instance instance-or-builder
                              predicate
                              [field ...]
                              [value ...])]))
              '(#:instance #:instance p [] []))

(check-equal? (syntax->datum
               (syntax-parse #'(#:builder)
                 [(k:structure-kws)
                  #'(k.builder k.instance-or-builder [k.field ...])]))
              '(#:builder #:builder []))

(test-exn
 "Check that () is rejected, as it has neither #:instance nor #:builder"
 (regexp (regexp-quote empty-err))
 (λ ()
   (syntax-parse #'()
     [(:structure-kws) #'()])))

(test-exn
 "Check that (#:instance [f1] [f2]) is rejected, as #:instance conflicts with
builder-style field declarations"
 (regexp (regexp-quote no-values-err))
 (λ ()
   (syntax-parse #'(#:instance [f1] [f2])
     [(:structure-kws) #'([field ...] instance)])))

(check-equal? (syntax->datum
               (syntax-parse #'(#:builder #:? p [f1] [f2])
                 [(:structure-kws) #'([field ...] builder)]))
              '([f1 f2] #:builder))

(check-equal?  (syntax-parse #'([f1] [f2]); #:? p 
                 [(:structure-kws) (cons (attribute builder)
                                         (syntax->datum #'([field ...])))])
               '(#f [f1 f2]))

;; This one is appropriately rejected
(check-exn #px"unexpected term"
           (λ ()
             (syntax-parse #'(#:instance #:a)
               [(:structure-kws) 'err])))
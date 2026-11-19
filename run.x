; # x-doc -- documents shown and converted on x-lang
;
; ## run.x -- the entry
;
; @description `x -l doc -- [OPTIONS] FILE [OUTPUT]`.
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
(import doc/base)

(set! %lang-name "doc")
(set! %repl-prompt "doc> ")

; The operands: what follows the "--" after the launcher's own options.
; x-os's launcher passes the engine's own flags ahead of them, with no
; "--" between; they are left out, so `x -l doc` there is a REPL too.
(def %engine-flag?
  (fn (_ a) (List any? (fn (_ f) (str=? a f)) (list "--batch" "--quiet" "--no-color"))))
(def %operands
  (fn (self l) (if (if (null? l) #f (%engine-flag? (first l))) (self (rest l)) l)))
(let ((ops (%operands (rest (Sys args (lit program))))))
  (unless (null? ops) (Sys exit (doc-main ops))))

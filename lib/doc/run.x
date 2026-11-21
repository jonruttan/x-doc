; # x-doc -- documents shown and converted on x-lang
;
; ## lib/doc/run.x -- the entry, the module doc/run
;
; @description `x -l doc -- [OPTIONS] FILE [OUTPUT]`.
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
; Importing it sets the session up and starts nothing; main runs the
; command the operands spell, and with none leaves the prompt to the
; wrapper.
(module doc/run)
(import doc/base doc-main)

(set! %lang-name "doc")
(set! %repl-prompt "doc> ")

; The operands: what follows the "--" after the launcher's own options.
; x-os's launcher passes the engine's own flags ahead of them, with no
; "--" between; they are left out, so `x -l doc` there is a REPL too.
(def %engine-flag?
  (fn (_ a) (List any? (fn (_ f) (str=? a f)) (list "--batch" "--quiet" "--no-color"))))
(def %operands
  (fn (self l) (if (if (null? l) #f (%engine-flag? (first l))) (self (rest l)) l)))

(def main
  (fn (_)
    (let ((ops (%operands (rest (Sys args (lit program))))))
      (unless (null? ops) (Sys exit (doc-main ops))))))

(provide doc/run main)

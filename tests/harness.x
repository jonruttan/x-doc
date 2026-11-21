; # x-doc -- documents shown and converted on x-lang
;
; ## tests/harness.x -- what the spec harness adds to the dialect
;
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
; The bundle kit's generator writes tests/lib/harness.gen.x: the dialect
; bundle.xon declares, the bundle's root on the import path, then this file.
(import doc/base)
(import x/sys/opts)
(import x/codec/document)
(import x/sys/file)

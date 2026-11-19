# The command line
# @weight 1

doc/cli declares its options to the platform's Opts: what parse accepts
is what usage prints.  doc-main answers the exit status.

## the declaration

### the usage names every option, short and long

```doc
(def text (Opts usage doc-options))
(write (List map (fn (_ s) (Str8 includes? s text)) (list "-t,--to" "-f,--from" "-i,--info" "-l,--list" "-w,--width" "-V,--version" "-h,--help" "x -l doc --")))
```
---
    (#t #t #t #t #t #t #t #t)

## the status

### 0 for a document shown or written, 1 for a file that cannot be read, 2 for a command line refused

```doc
(def out "tests/lib/out.html")
(write (list (doc-main (list "tests/fixtures/notes.md" out))
             (first (doc-open out ()))
             (doc-main (list "-t" "markdown" "tests/fixtures/page.html" "tests/lib/out.bin"))
             (first (doc-open "tests/lib/out.bin" "markdown"))
             (doc-main (list "tests/fixtures/none.md"))
             (doc-main (list "tests/fixtures/notes.md" "tests/lib/out.bin"))
             (doc-main (list "-t" "rtf" "tests/fixtures/notes.md"))
             (doc-main (list "-f" "rtf" "tests/fixtures/notes.md"))
             (doc-main (list "-w" "3" "tests/fixtures/notes.md"))
             (doc-main (list "--nope" "tests/fixtures/notes.md"))
             (doc-main ())
             (doc-main (list "a" "b" "c"))))
```
---
    (0 "html" 0 "markdown" 1 2 2 2 2 2 2 2)

; # x-doc -- documents shown and converted on x-lang
;
; ## doc/cli.x -- the command line
;
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
;   x -l doc -- FILE                    the document, laid out as text
;   x -l doc -- -i FILE                 what the document is
;   x -l doc -- FILE OUTPUT             the document written as OUTPUT's format
;   x -l doc -- -t FORMAT FILE          the document written as FORMAT
;   x -l doc -- -e FILE [OUTPUT]        the document edited as Markdown
;
; The formats are the platform's: (Document formats) names them, (Document
; read) reads a file as one and (Document write) writes one.  A file's
; format is its name's ending, or a PDF's signature, unless --from or --to
; names it; a file no format claims is read as text.  The FILE - is
; standard input, read to its end.

(module doc/cli)

(import x/sys/posix)
(import x/sys/file)
(import x/sys/opts)
(import x/codec/document)

(import x/core/doors str-byte-len str-byte-ref)

(def doc-version "0.1.0")

; The options and the help text, one declaration: what parse accepts is
; what usage prints.
(def doc-options
  (Opts declare "x -l doc --" "[OPTIONS] FILE [OUTPUT]"
    "Show a document, say what it is, or write it in another format.\nA format is one of markdown, html, pdf and text.  With no OUTPUT and no --to, the document is laid out as text.  The FILE - is standard input: text unless it is a PDF or --from names its format."
    (list (Opts arg "-t" "--to" "FORMAT" "Write the document as FORMAT, to OUTPUT or standard output")
          (Opts arg "-f" "--from" "FORMAT" "Read FILE as FORMAT, whatever its name")
          (Opts flag "-i" "--info" "Print the document's format, title and size, and exit")
          (Opts flag "-e" "--edit" "Edit the document as Markdown in $VISUAL, $EDITOR or vi, and write it back, to OUTPUT if given")
          (Opts flag "-l" "--list" "Print the formats and the endings each is known by, and exit")
          (Opts arg "-w" "--width" "N" "Columns of text: the terminal's, or 80, unless given; 10 at least")
          (Opts flag "-V" "--version" "Print the version and exit")
          (Opts flag "-h" "--help" "Print this help and exit"))
    (pair (lit help) #f)))

(def %say (fn (_ fd text) (Sys fd-write fd text)))

(def %to-int
  (fn (_ s) (guard (e ()) ((prim-ref (lit convert) (lit to)) s (Type named INTEGER) 10))))

(def %err-text
  (fn (_ e)
    (match ((Err err? e) (e msg))
           ((str? e) e)
           (#t (Err code-of e)))))

(def %format?
  (fn (_ name) (List any? (fn (_ f) (str=? (first f) name)) (Document formats))))

; All a descriptor gives and how many bytes that is, (BYTES . SIZE): read a
; block at a time to its end, a NUL put after the last byte so that the
; buffer is also a string.
(def doc-input
  (fn (_ fd)
    (import x/codec/bytes)
    (def w (Bytes writer))
    (def block (first (Bytes zeros 65536)))
    ((fn (self)
       ((fn (_ n)
          (match ((< n 0) (Err raise (lit io) "cannot read" "-"))
                 ((< 0 n) (do (Bytes put w (list block 0 n)) (self)))
                 (#t ())))
        (File read fd block 65536))))
    (def size (Bytes size w))
    (Bytes put-u8 w 0)
    (pair (first (Bytes written w)) size)))

; Standard input: the launcher's boot stream holds descriptor 0 and the
; caller's input waits on 3, the platform's arrangement, so 3 is taken
; back as 0 before the read.
(def %standard-input
  (fn (_)
    (guard (e ()) (do (Sys dup2 3 0) (Sys close 3)))
    (doc-input 0)))

; The file at PATH and how many bytes it holds, (BYTES . SIZE); the path
; "-" is standard input.
(def %file
  (fn (_ path)
    (def type (match ((str=? path "-") (lit input)) (#t (File type path))))
    (match ((eq? type (lit input)) (%standard-input))
           ((null? type) (Err raise (lit io) "no such file" path))
           ((not (eq? type (lit file))) (Err raise (lit io) "not a file to read" path))
           (#t (pair (File read-all path) (rest (Assoc find (lit size) (File stat path))))))))

; The file at PATH and the document it holds, read as FORMAT or, FORMAT
; nil, as its name and first bytes say: ((BYTES . SIZE) FORMAT TITLE . BLOCKS).
(def %load
  (fn (_ path format)
    (def got (%file path))
    (def as (match ((not (null? format)) format)
                   (#t ((fn (_ f) (match ((null? f) "text") (#t f))) (Document format path (first got))))))
    (pair got (pair as (Document read as (first got) (rest got))))))

; The document at PATH: (FORMAT TITLE . BLOCKS).
(def doc-open (fn (_ path format) (rest (%load path format))))

; The strings an inline run is made of, in order; a line end is a space.
(def %inline-texts
  (fn (self inlines)
    (List flat-map
      (fn (_ x)
        (match ((str? x) (list x))
               ((eq? (first x) (lit code)) (list (List ref 1 x)))
               ((match ((eq? (first x) (lit emph)) #t) (#t (eq? (first x) (lit strong)))) (self (List ref 1 x)))
               ((match ((eq? (first x) (lit link)) #t) (#t (eq? (first x) (lit image)))) (self (List ref 3 x)))
               ((match ((eq? (first x) (lit softbreak)) #t) (#t (eq? (first x) (lit hardbreak)))) (list " "))
               (#t ())))
      inlines)))
; The text of each block that holds text: a heading's or a paragraph's
; inlines joined, so a word set in two styles is one word.
(def %block-texts
  (fn (self blocks)
    (List flat-map
      (fn (_ b)
        (match ((eq? (first b) (lit heading)) (list (Str8 join "" (%inline-texts (List ref 2 b)))))
               ((eq? (first b) (lit paragraph)) (list (Str8 join "" (%inline-texts (List ref 1 b)))))
               ((eq? (first b) (lit code-block)) (list (List ref 2 b)))
               ((eq? (first b) (lit block-quote)) (self (List ref 1 b)))
               ((eq? (first b) (lit list)) (List flat-map (fn (_ item) (self item)) (List ref 4 b)))
               (#t ())))
      blocks)))
(def %headings
  (fn (self blocks)
    (List fold
      (fn (_ n b)
        (match ((eq? (first b) (lit heading)) (+ n 1))
               ((eq? (first b) (lit block-quote)) (+ n (self (List ref 1 b))))
               ((eq? (first b) (lit list)) (List fold (fn (_ m item) (+ m (self item))) n (List ref 4 b)))
               (#t n)))
      0 blocks)))
; How many runs of bytes that are not white space S holds from I, N
; counted so far, IN whether I is inside one.
(def %count
  (fn (self s i in n)
    (match ((= i (str-byte-len s)) n)
           ((< 32 (str-byte-ref s i)) (self s (+ i 1) #t (match (in n) (#t (+ n 1)))))
           (#t (self s (+ i 1) #f n)))))
(def %words
  (fn (_ blocks) (List fold (fn (_ n s) (+ n (%count s 0 #f 0))) 0 (%block-texts blocks))))

; How many pages the PDF in GOT, (BYTES . SIZE), has.
(def %pages
  (fn (_ got)
    (import x/codec/pdf)
    (List length (Pdf pages (Pdf open (first got) (rest got))))))

; What the document at PATH is, a line a fact: its format, its title (the
; format's own, else its first heading), a PDF's pages, its headings and
; its words.
(def doc-info
  (fn (_ path format)
    (def all (%load path format))
    (def doc (rest all))
    (def blocks (rest (rest doc)))
    (def title (match ((null? (first (rest doc))) (Document title blocks)) (#t (first (rest doc)))))
    (def row (fn (_ name value) (Str8 append (Str8 pad-right 9 #\space name) value "\n")))
    (Str8 append
      (row "file" path)
      (row "format" (first doc))
      (match ((null? title) "") (#t (row "title" title)))
      (match ((str=? (first doc) "pdf")
               (row "pages" (%number->str (%pages (first all)))))
             (#t ""))
      (row "headings" (%number->str (%headings blocks)))
      (row "words" (%number->str (%words blocks))))))

; The document at PATH, read as FROM (nil: as it says) and written as TO,
; text WIDTH columns wide: the file, (BUF START LENGTH).
(def doc-convert
  (fn (_ path from to width)
    (def doc (doc-open path from))
    (Document write to (rest (rest doc)) (first (rest doc)) width)))

; The whole of FILE, (BUF START LENGTH), written to FD.
(def %emit
  (fn (self fd file)
    (def n (List ref 2 file))
    (when (< 0 n)
      ((fn (_ wrote)
         (match ((< wrote 1) (Err raise (lit io) "cannot write" ()))
                (#t (self fd (list (first file) (+ (List ref 1 file) wrote) (- n wrote))))))
       (File write fd (match ((= (List ref 1 file) 0) (first file)) (#t (Str8 sub (List ref 1 file) n (first file)))) n)))))
(def %save
  (fn (_ path file)
    (def fd (File open path (list (lit wronly) (lit creat) (lit trunc)) 420))
    (when (< fd 0) (Err raise (lit io) "cannot write" path))
    (def failed (guard (e e) (do (%emit fd file) ())))
    (File close fd)
    (unless (null? failed) (error failed))))

; --- editing -----------------------------------------------------------------

; The editor's command as words: $VISUAL, else $EDITOR, else vi.
(def %editor
  (fn (_)
    (def named
      (fn (_ name) ((fn (_ v) (match ((null? v) ()) ((str=? (Str8 trim v) "") ()) (#t v))) (guard (e ()) (Sys getenv name)))))
    (def command (match ((not (null? (named "VISUAL"))) (named "VISUAL")) ((not (null? (named "EDITOR"))) (named "EDITOR")) (#t "vi")))
    (List filter (fn (_ w) (not (str=? w ""))) (Str8 split " " command))))

; A new file for the editor, its name ending .md so an editor knows what
; it holds: its path.
(def %scratch
  (fn (_)
    (def made (File temp (Str8 append ((fn (_ d) (match ((null? d) "/tmp") (#t d))) (guard (e ()) (Sys getenv "TMPDIR"))) "/x-doc-")))
    (File close (first made))
    (File rename (rest made) (Str8 append (rest made) ".md"))
    (Str8 append (rest made) ".md")))

; EDITOR, a command as words, run on PATH: how it ended.
(def %run
  (fn (_ editor path)
    (import x/sys/proc)
    (Proc run! (List append editor (list path)))))

; The document at PATH edited as Markdown by EDITOR and written back: to
; OUTPUT, or over PATH when OUTPUT is nil, as the format TO names or, TO
; nil, as the name written to says.  The document is written as Markdown
; to a file of its own, the editor is run on it, and what it leaves is
; read and written in the format; when it leaves the text as it was, or
; ends with a status other than 0, nothing is written.  A Markdown or a
; text file edited in place is given to the editor as it is.  Answers
; (STATUS . WROTE?).
(def doc-edit
  (fn (_ path from to output editor width)
    (def doc (doc-open path from))
    (def format (match ((not (null? to)) to)
                       ((null? output) (first doc))
                       (#t ((fn (_ f) (match ((null? f) "text") (#t f))) (Document format output)))))
    (def plain? (match ((str=? format "markdown") #t) (#t (str=? format "text"))))
    (match
      ((match ((null? output) (match ((str=? format (first doc)) plain?) (#t #f))) (#t #f))
        ((fn (_ before)
           (def status (%run editor path))
           (pair status (match ((= status 0) (not (str=? before (File read-all path)))) (#t #f))))
         (File read-all path)))
      (#t
        ((fn (_ scratch before)
           (File write-all scratch before)
           (def status (%run editor scratch))
           (def after (File read-all scratch))
           (File unlink scratch)
           (match ((not (= status 0)) (pair status #f))
                  ((str=? before after) (pair 0 #f))
                  (#t (do (%save (match ((null? output) path) (#t output))
                                 (Document write format (rest (Document read "markdown" after)) (first (rest doc)) width))
                          (pair 0 #t)))))
         (%scratch) (first (Document write "markdown" (rest (rest doc)))))))))

; The terminal's columns, 80 when it will not say or says fewer than 10.
(def %terminal
  (fn (_)
    (import x/repl/term)
    ((fn (_ size) (match ((null? size) 80) ((< (first size) 10) 80) (#t (first size))))
     (guard (e ()) (Term window 1)))))

; The columns of text: WIDTH when given, else the terminal's when standard
; output is one, else 80.
(def %columns
  (fn (_ width)
    (match ((not (null? width)) width) ((Sys isatty 1) (%terminal)) (#t 80))))

(def %list
  (fn (_)
    (Str8 join ""
      (List map (fn (_ f) (Str8 append (Str8 pad-right 9 #\space (first f)) (Str8 join " " (first (rest f))) "\n"))
                (Document formats)))))

; The format OUTPUT is written as: TO when given, else its name's.
(def %target
  (fn (_ to output)
    (match ((not (null? to)) to)
           ((null? output) "text")
           (#t (Document format output)))))

; ARGS, the command line after the launcher's options: the exit status.
(def doc-main
  (fn (_ args)
    (def opts (Opts parse doc-options args))
    (def files (Opts operands opts))
    (def from (Opts value opts "-f"))
    (def to (Opts value opts "-t"))
    (def given (Opts value opts "-w"))
    (def width (match ((null? given) ()) (#t (%to-int given))))
    (def refuse (fn (_ text) (%say 2 (Str8 append "x-doc: " text "\n")) 2))
    (def named (fn (_ f) (match ((null? f) #t) (#t (%format? f)))))
    (match
      ((not (null? (Opts unknown opts)))
        (do (%say 2 (Str8 append "x-doc: no such option: " (Opts unknown opts) "\n" (Opts usage doc-options))) 2))
      ((Opts on? opts "-h") (do (%say 1 (Opts usage doc-options)) 0))
      ((Opts on? opts "-V") (do (%say 1 (Str8 append "x-doc " doc-version "\n")) 0))
      ((Opts on? opts "-l") (do (%say 1 (%list)) 0))
      ((not (named from)) (refuse (Str8 append "--from takes a format --list names, not " from)))
      ((not (named to)) (refuse (Str8 append "--to takes a format --list names, not " to)))
      ((match ((null? given) #f) ((null? width) #t) (#t (< width 10)))
        (refuse "--width takes a number of columns, 10 or more"))
      ((match ((null? files) #t) (#t (< 2 (List length files)))) (do (%say 2 (Opts usage doc-options)) 2))
      ((match ((Opts on? opts "-e") (str=? (first files) "-")) (#t #f))
        (refuse "--edit takes a file, not standard input"))
      ((match ((not (null? to)) #f) ((null? (rest files)) #f) (#t (null? (Document format (first (rest files))))))
        (refuse (Str8 append "no format is known by this name, name one with --to: " (first (rest files)))))
      (#t
        (guard (e (do (%say 2 (Str8 append "x-doc: " (%err-text e) ": " (first files) "\n")) 1))
          (match
            ((Opts on? opts "-i") (do (%say 1 (doc-info (first files) from)) 0))
            ((Opts on? opts "-e")
              ; The launcher holds descriptor 0 and the terminal waits on 3:
              ; it is taken back, so the editor has it.
              (do (guard (e ()) (do (Sys dup2 3 0) (Sys close 3)))
                  ((fn (_ ended)
                     (match ((= (first ended) 0) 0)
                            (#t (do (%say 2 (Str8 append "x-doc: the editor ended with status " (%number->str (first ended))
                                                         ", and nothing was written: " (first files) "\n"))
                                    1))))
                   (doc-edit (first files) from to
                             (match ((null? (rest files)) ()) (#t (first (rest files))))
                             (%editor) (match ((null? width) 80) (#t width))))))
            (#t
              ((fn (_ output)
                 ((fn (_ file) (match ((null? output) (%emit 1 file)) (#t (%save output file))) 0)
                  (doc-convert (first files) from (%target to output) (%columns width))))
               (match ((null? (rest files)) ()) (#t (first (rest files))))))))))))

(provide doc/cli doc-version doc-main doc-options doc-open doc-info doc-convert doc-input doc-edit)

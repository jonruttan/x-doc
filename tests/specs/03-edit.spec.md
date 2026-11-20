# Editing
# @weight 1

doc-edit writes a document as Markdown, runs an editor on that, and
writes what the editor leaves in the document's format.  The editor here
is a script that adds a paragraph.

## through Markdown

### an HTML page edited to another file: the page with the paragraph added, the first as it was

```doc
(def ed (list "/bin/sh" "tests/fixtures/edit.sh"))
(def was (File read-all "tests/fixtures/page.html"))
(write (list (doc-edit "tests/fixtures/page.html" () () "tests/lib/edit-out.html" ed 80)
             (doc-open "tests/lib/edit-out.html" ())
             (str=? was (File read-all "tests/fixtures/page.html"))))
```
---
    ((0 . #t) ("html" "A page" ('heading 1 ("Page")) ('paragraph ("Some " ('strong ("bold")) " text.")) ('paragraph ("Added by the editor."))) #t)

### a PDF edited in place is the PDF again, its title kept; another format is named by the output or --to

```doc
(def ed (list "/bin/sh" "tests/fixtures/edit.sh"))
(File copy "tests/fixtures/hello.pdf" "tests/lib/edit-in.pdf")
(write (list (doc-edit "tests/lib/edit-in.pdf" () () () ed 80)
             (first (doc-open "tests/lib/edit-in.pdf" ()))
             (first (rest (doc-open "tests/lib/edit-in.pdf" ())))
             (List last (doc-open "tests/lib/edit-in.pdf" ()))
             (doc-edit "tests/fixtures/hello.pdf" () () "tests/lib/edit-pdf.md" ed 80)
             (List last (Str8 split "\n\n" (File read-all "tests/lib/edit-pdf.md")))
             (doc-edit "tests/fixtures/page.html" () "markdown" "tests/lib/edit-named.out" ed 80)
             (File read-all "tests/lib/edit-named.out")))
```
---
    ((0 . #t) "pdf" "Fixture title" ('paragraph ("Added by the editor.")) (0 . #t) "Added by the editor.\n" (0 . #t) "# Page\n\nSome **bold** text.\n\nAdded by the editor.\n")

### an editor that leaves the text as it was, or ends badly, writes nothing

```doc
(write (list (doc-edit "tests/fixtures/page.html" () () "tests/lib/edit-same.html" (list "/bin/sh" "-c" "exit 0") 80)
             (File exists? "tests/lib/edit-same.html")
             (doc-edit "tests/fixtures/page.html" () () "tests/lib/edit-bad.html" (list "/bin/sh" "-c" "exit 3") 80)
             (File exists? "tests/lib/edit-bad.html")))
```
---
    ((0 . #f) #f (3 . #f) #f)

## in place

### a Markdown file and a text file are given to the editor as they are

```doc
(def ed (list "/bin/sh" "tests/fixtures/edit.sh"))
(File copy "tests/fixtures/notes.md" "tests/lib/edit-notes.md")
(File copy "tests/fixtures/plain.txt" "tests/lib/edit-plain.txt")
(write (list (doc-edit "tests/lib/edit-notes.md" () () () ed 80)
             (str=? (File read-all "tests/lib/edit-notes.md") (Str8 append (File read-all "tests/fixtures/notes.md") "\nAdded by the editor.\n"))
             (doc-edit "tests/lib/edit-plain.txt" () () () ed 80)
             (File read-all "tests/lib/edit-plain.txt")
             (doc-edit "tests/lib/edit-notes.md" () () () (list "/bin/sh" "-c" "exit 0") 80)))
```
---
    ((0 . #t) #t (0 . #t) "plain text\n  kept as written\n\nAdded by the editor.\n" (0 . #f))

## the command line

### --edit is refused standard input

```doc
(write (list (doc-main (list "-e" "-")) (Str8 includes? "-e,--edit" (Opts usage doc-options))))
```
---
    (2 #t)

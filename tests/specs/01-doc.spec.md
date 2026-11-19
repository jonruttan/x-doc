# Documents
# @weight 1

doc-open reads a file as the format its name or first bytes give it,
doc-info says what it is, and doc-convert writes it in another format.

## opening

### a file's format is its name's ending, a PDF's its signature, and text when no format claims it

```doc
(write (list (doc-open "tests/fixtures/notes.md" ())
             (doc-open "tests/fixtures/page.html" ())
             (doc-open "tests/fixtures/plain.txt" ())
             (first (doc-open "tests/fixtures/hello.pdf" ()))
             (first (doc-open "LICENSE" ()))
             (doc-open "tests/fixtures/plain.txt" "markdown")))
```
---
    (("markdown" () ('heading 1 ("Notes")) ('paragraph ("A " ('emph ("small")) " document with a " ('link "https://example.com" () ("link")) " and " ('code "code") ".")) ('list #f () #t ((('paragraph ("one"))) (('paragraph ("two"))))) ('heading 2 ("More")) ('block-quote (('paragraph ("quoted"))))) ("html" "A page" ('heading 1 ("Page")) ('paragraph ("Some " ('strong ("bold")) " text."))) ("text" () ('code-block "" "plain text\n  kept as written\n")) "pdf" "text" ("markdown" () ('paragraph ("plain text" ('softbreak) "kept as written"))))

### a file not there, and a directory

```doc
(write (list (guard (e (e msg)) (doc-open "tests/fixtures/none.md" ())) (guard (e (e msg)) (doc-open "tests" ()))))
```
---
    ("no such file" "not a file to read")

## info

### a line a fact: a PDF's title is its own and it has pages; another's is its first heading

```doc
(write (list (doc-info "tests/fixtures/hello.pdf" ()) (doc-info "tests/fixtures/notes.md" ()) (doc-info "tests/fixtures/plain.txt" ())))
```
---
    ("file     tests/fixtures/hello.pdf\nformat   pdf\ntitle    Fixture title\npages    1\nheadings 1\nwords    27\n" "file     tests/fixtures/notes.md\nformat   markdown\ntitle    Notes\nheadings 2\nwords    14\n" "file     tests/fixtures/plain.txt\nformat   text\nheadings 0\nwords    5\n")

## converting

### Markdown as HTML, as text at a width, and as Markdown again

```doc
(write (list (first (doc-convert "tests/fixtures/notes.md" () "html" 80))
             (first (doc-convert "tests/fixtures/notes.md" () "text" 30))
             (first (doc-convert "tests/fixtures/notes.md" () "markdown" 80))))
```
---
    ("<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"utf-8\">\n<title>Notes</title>\n</head>\n<body>\n<h1>Notes</h1>\n<p>A <em>small</em> document with a <a href=\"https://example.com\">link</a> and <code>code</code>.</p>\n<ul>\n<li>one</li>\n<li>two</li>\n</ul>\n<h2>More</h2>\n<blockquote>\n<p>quoted</p>\n</blockquote>\n</body>\n</html>\n" "Notes\n\nA small document with a link\nand code.\n\n• one\n• two\n\nMore\n\n│ quoted\n" "# Notes\n\nA *small* document with a [link](https://example.com) and `code`.\n\n- one\n- two\n\n## More\n\n> quoted\n")

### a PDF and an HTML page as Markdown

```doc
(write (list (first (doc-convert "tests/fixtures/hello.pdf" () "markdown" 80))
             (first (doc-convert "tests/fixtures/page.html" () "markdown" 80))))
```
---
    ("# A PDF fixture\n\nThis paragraph is set on two lines, the first reaching the margin and a word broken across them, in **bold**.\n\nA second paragraph.\n" "# Page\n\nSome **bold** text.\n")

### Markdown as a PDF, read back: the title is the first heading

```doc
(import x/codec/document)
(def out (doc-convert "tests/fixtures/notes.md" () "pdf" 80))
(write (list (Document format "out" (first out)) (Document read "pdf" (first out) (List ref 2 out))))
```
---
    ("pdf" ("Notes" ('heading 1 ("Notes")) ('paragraph ("A " ('emph ("small")) " document with a link and " ('code "code") ".")) ('paragraph ("• one")) ('paragraph ("• two")) ('heading 2 ("More")) ('paragraph ("quoted"))))

## standard input

### a descriptor is read to its end: its bytes, a string too, and how many

```doc
(def fd (File open "tests/fixtures/hello.pdf" (lit rdonly)))
(def got (doc-input fd))
(File close fd)
(def md (File open "tests/fixtures/notes.md" (lit rdonly)))
(def text (doc-input md))
(File close md)
(write (list (rest got) (= (rest got) (rest (Assoc find (lit size) (File stat "tests/fixtures/hello.pdf"))))
             (Document format "-" (first got)) (first (Document read "pdf" (first got) (rest got)))
             (str=? (first text) (File read-all "tests/fixtures/notes.md")) (null? (Document format "-" (first text)))))
```
---
    (991 #t "pdf" "Fixture title" #t #t)

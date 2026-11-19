# x-doc

Documents shown, described and converted, written in
[x-lang](https://github.com/jonruttan/x-lang) and loaded as a lang.  It
reads Markdown, HTML, PDF and plain text, and writes each of them.

    x -l doc -- FILE
    x -l doc -- -i FILE
    x -l doc -- FILE OUTPUT
    x -l doc -- -t FORMAT FILE [OUTPUT]
    x -l doc -- -l | -V | -h

## Showing

With a file and nothing else, the document is laid out as text: headings,
paragraphs wrapped, lists marked, quotes barred and code kept as written,
as wide as the terminal, or 80 columns when the output is not one.
`-w N`, `--width N`, sets the columns.

    x -l doc -- notes.md
    x -l doc -- paper.pdf | less

## Describing

`-i`, `--info`, prints what the document is, a line a fact: the file, its
format, its title, a PDF's pages, and how many headings and words it
holds.  The title is the format's own, an HTML page's `<title>` or a PDF's
`/Title`, and the first heading's text when it has none.

    x -l doc -- -i paper.pdf

## Converting

With an output file, the document is written in the format the output's
name ends with.  `-t FORMAT`, `--to FORMAT`, names the format instead,
and with no output file the document goes to standard output.

    x -l doc -- paper.pdf paper.md
    x -l doc -- notes.md notes.pdf
    x -l doc -- -t html notes.md > notes.html

## Formats

| Format | Endings | Read as | Written as |
|---|---|---|---|
| `markdown` | `.md` `.markdown` `.mdown` | CommonMark | CommonMark |
| `html` | `.html` `.htm` | Its headings, paragraphs, lists, quotes, code and links; a table a paragraph a row | A page under the document's title |
| `pdf` | `.pdf` | Its text as headings and paragraphs, bold and italic kept | US Letter pages in Helvetica and Courier |
| `text` | `.txt` `.text` | One block that keeps its lines | The document laid out in columns |

`-l`, `--list`, prints the formats.  A file's format is its name's ending;
a file that begins with a PDF's signature is a PDF whatever its name, and
a file no format claims is read as text.  `-f FORMAT`, `--from FORMAT`,
reads the file as that format whatever its name.

The formats are x-lang's: `x/codec/document` names them and reads and
writes them, and a format added there is one this command has.

## Standard input

The file `-` is standard input, read to its end.  It is text unless it is
a PDF or `--from` names its format.

    curl -s https://example.com/ | x -l doc -- -f html -t markdown -

## Exit status

0 when the document was shown or written, 1 when the file could not be
read or the output written, 2 for a command line refused.

## Install

    make install

copies the bundle to `<share>/langs/doc`, where `x -l doc` finds it.
`make check` runs the spec suite.

## License

MIT No Attribution (MIT-0).

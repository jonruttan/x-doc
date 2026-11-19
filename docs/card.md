# x-doc card

## Run

```sh
x -l doc -- FILE
x -l doc -- -i FILE
x -l doc -- FILE OUTPUT
x -l doc -- -t FORMAT FILE [OUTPUT]
printf '*a* b\n' | x -l doc -- -f markdown - -> a b
printf '<h1>Hi</h1>' | x -l doc -- -f html -t markdown - -> # Hi
printf '# Hi\n' | x -l doc -- -f markdown -t html - | grep h1 -> <h1>Hi</h1>
x -l doc -- -t markdown tests/fixtures/page.html | head -1 -> # Page
x -l doc -- -i tests/fixtures/hello.pdf | grep pages -> pages    1
x -l doc -- -l | head -1 -> markdown .md .markdown .mdown
x -l doc -- -t rtf README.md 2>/dev/null; echo $? -> 2
x -l doc -- none.md 2>/dev/null; echo $? -> 1
```

| Operand  | Meaning                                                      |
|----------|--------------------------------------------------------------|
| `--`     | ends x's own options; this command's options follow it       |
| `FILE`   | the document to read; `-` is standard input, read to its end |
| `OUTPUT` | where to write it; its name's ending names the format        |

## Options

| Option      | Does                                                      |
|-------------|-----------------------------------------------------------|
| none        | lays the document out as text, as wide as the terminal    |
| `-t FORMAT` | writes the document as FORMAT, to OUTPUT or standard out  |
| `-f FORMAT` | reads FILE as FORMAT, whatever its name                   |
| `-i`        | prints the format, title, a PDF's pages, headings, words  |
| `-l`        | prints the formats and the endings each is known by       |
| `-w N`      | columns of text; the terminal's or 80 unless given        |
| `-V` `-h`   | the version; the help                                     |

## Formats

| Format     | Endings                    | Read as, written as              |
|------------|----------------------------|----------------------------------|
| `markdown` | `.md` `.markdown` `.mdown` | CommonMark, both ways            |
| `html`     | `.html` `.htm`             | its blocks; a page under a title |
| `pdf`      | `.pdf`                     | its text; US Letter pages        |
| `text`     | `.txt` `.text`             | one block; laid out in columns   |

| A file's format is         | When                                       |
|----------------------------|--------------------------------------------|
| what `-f` or `-t` names    | always, first                              |
| `pdf`                      | it begins with a PDF's signature           |
| its name's ending          | a format knows the ending                  |
| `text`                     | no format claims it, standard input too    |

## Status

| Status | Means                                               |
|--------|-----------------------------------------------------|
| `0`    | the document was shown or written                   |
| `1`    | the file could not be read, or the output written   |
| `2`    | the command line was refused                        |

## Differs

| Here                                     | In a converter you may know     |
|------------------------------------------|---------------------------------|
| a PDF read back has lists as paragraphs  | structure kept                  |
| an HTML table is a paragraph a row       | a table                         |
| piped input is text unless `-f` says     | Markdown assumed                |

## More

| Where                          | What                               |
|--------------------------------|------------------------------------|
| `README.md`                    | each command, with examples        |
| `tests/specs/01-doc.spec.md`   | one case a behaviour               |
| x-lang `docs/document.md`      | the tree every format is read into |

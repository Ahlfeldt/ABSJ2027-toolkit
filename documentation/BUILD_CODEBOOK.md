# Building the codebook

`CODEBOOK.tex` is the authoritative editable source; `CODEBOOK.pdf` is its compiled output.
The earlier `CODEBOOK.md` is retained as an initial prose draft, not the maintained source.

The LaTeX source is self-contained. Upload it to a new Overleaf project, or compile
from this directory with a standard TeX Live or MiKTeX installation:

```text
pdflatex CODEBOOK.tex
pdflatex CODEBOOK.tex
```

Alternatively, use `tectonic CODEBOOK.tex` (tested with Tectonic 0.17.0).
A first Tectonic run needs network access to obtain its TeX packages.

The formatting follows the AB2022 codebook's serif academic layout, appendix
section numbering, booktabs tables, and ruled, numbered pseudocode. The article
class (11 pt, A4), margins, one-and-a-half spacing, and algorithm2e options follow
the skyscraper paper's Overleaf preamble. No local reference-project paths or
external bibliography files are required to build the codebook.

Packages: inputenc, fontenc, amsfonts, amsmath, amssymb, amsthm, geometry,
setspace, vmargin, array, booktabs, tabularx, longtable, ragged2e, algorithm2e,
and hyperref. Standard distributions include these packages.

The PDF was checked for equation and algorithm references, page layout, and text
overflow. The toolkit MATLAB code was not modified in this documentation update.

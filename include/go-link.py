#!/usr/bin/env python
from pandocfilters import toJSONFilter, RawInline
from re import match

"""
Pandoc filter that replaces all references to GO terms with
links to the corresponding web page. Only HTML output is affected.
"""


def html(s):
    return RawInline('html', s)


def linkGO(key, value, format, meta):
    if key == 'Str' and (format == 'html5' or format == 'html') and match("GO:\d{7}$", value) is not None:
        return [html('<a href="http://amigo.geneontology.org/amigo/term/' + value + '">')] + value + [html('</a>')]

if __name__ == "__main__":
    toJSONFilter(linkGO)

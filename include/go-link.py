#!/usr/bin/env python
from pandocfilters import toJSONFilter, RawInline, Str
import re

"""
Pandoc filter that replaces all references to GO terms with
links to the corresponding web page. Only HTML output is affected.
"""


def html(s):
    return RawInline('html', s)


def linkGO(key, value, format, meta):
    if key == 'Str':
        id = re.findall("GO:\d{7}", value)
        if  len(id) > 0:
            return [html('<a href="http://amigo.geneontology.org/amigo/term/' + id[0] + '" target="_blank">')] + [Str(value)] + [html('</a>')]

if __name__ == "__main__":
    toJSONFilter(linkGO)

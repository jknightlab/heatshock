#!/usr/bin/env python

"""
Pandoc filter to remove divs with class 'hidden-print' from
LaTeX ouput.
"""

from pandocfilters import toJSONFilter, Div

def removeHidden(key, value, format, meta):
  if key == 'Div':
    [[ident, classes, kvs], contents] = value
      if "hidden-print" in classes:
        if format == "latex":
          return []

if __name__ == "__main__":
    toJSONFilter(removeHidden)

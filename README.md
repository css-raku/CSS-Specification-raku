perl6-CSS-Specification
=======================
This is a Perl 6 module for parsing sets of CSS property definitions.

These are widely used throughout the W3C CSS Specifications to describe properties.
The syntax is described in http://www.w3.org/TR/CSS21/about.html#property-defs.

An example, from http://www.w3.org/TR/CSS21/propidx.html:

    'content'	normal
               | none
               | [  <string> | <uri> | <counter> | attr(<identifier>)
                  | open-quote | close-quote | no-open-quote | no-close-quote
                 ]+
               | inherit


Programs
========
This module provides `css-gen-properties`. A program for translating property definitions
to grammars, actions or interface classes.

See Also
========
See [BUILD.pl](https://github.com/p6-css/perl6-CSS-Module/blob/master/BUILD.pl) in [CSS::Module](https://github.com/p6-css/perl6-CSS-Module).

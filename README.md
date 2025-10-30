[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Specification]](https://css-raku.github.io/CSS-Specification-raku)


CSS-Specification-raku
=======================

This is a Raku module for parsing CSS property definitions.

These are widely used throughout the W3C CSS Specifications to describe properties.
The syntax is described in http://www.w3.org/TR/CSS21/about.html#property-defs.

An example, from http://www.w3.org/TR/CSS21/propidx.html:

    'content'	normal
               | none
               | [  <string> | <uri> | <counter> | attr(<identifier>)
                  | open-quote | close-quote | no-open-quote | no-close-quote
                 ]+
               | inherit

## Grammars and Classes

- `CSS::Specification::Defs` + `CSS::Specification::Defs::Actions` - is a grammar which maps property specification terminology to CSS Core syntax and defines any newly introduced terms. For example `integer` is mapped to `int`.

## See Also
- [CSS::Specification::Compiler](https://github.com/css-raku/CSS-Specification-Compiler-raku.git) - an unreleased RakuAST based compiler for property definitions
- [make-modules.raku](https://github.com/css-raku/CSS-Module-raku/blob/master/make-modules.raku) in [CSS::Module](https://css-raku.github.io/CSS-Module-raku).

grammar CSS::Specification::Extended {
    use CSS::Specification;
    also is CSS::Specification;

    # A few extensions to the W3C property definition syntax, as used by
    # CSS::Module, CSS::Properties tool-chain

    # ! prefix (repeatable) on alternations, to force higher precedence
    # e.g. 'font-family'	[ <family-name> | !<generic-family> ]#
    rule term-options   { [$<precedence>='!'* <term=.term-combo>] +% '|' }

    # allow a custom rule as a property setter
    # e.g. font	[ [ <'font-style'> || <'font-variant'=.font-variant-css2> || ...
    rule value:sym<prop-alias>    { '<'~'>' [<val=.prop-val>'=.'[<rule=.id>|<rule=.prop-val>]] }

    # leading dot on property reference - to share syntax, but not set property
    # e.g. flex-basis	content | <.'width'>
    token property-val:sym<css3>  { '<'~'>' [[$<inline>='.']? <val=.prop-val>] }

    # allow ':', ';' as delimiters
    # e.g. <font-feature-property> = <font-feature-value-name> : <font-feature-index> <any-args> ;?
    rule value:sym<delim>  { < , / : ; > }
}

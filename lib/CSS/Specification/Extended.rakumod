grammar CSS::Specification::Extended {
    use CSS::Specification;
    also is CSS::Specification;

    # A few extensions to the W3C property definition syntax, as used by
    # the specification compiler to support CSS::Module, and CSS::Properties

    # ! prefix (repeatable) on alternations, to force higher parsing precedence
    # e.g. 'font-family'	[ <family-name> | !<generic-family> ]#
    rule term-options   { [$<precedence>='!'* <term=.term-combo>] +% '|' }

    # upgrade a general rule to act as a property setter
    # e.g. font	[ [ <'font-style'> || <'font-variant'=.font-variant-css2> || ...
    rule value:sym<prop-alias>    { '<'~'>' [<val=.prop-val>'=.'[<rule=.id>|<rule=.prop-val>]] }

    # downgrade property definition syntax to act as a general rule
    # e.g. flex-basis	content | <.'width'>
    token property-val:sym<css3>  { '<'~'>' [[$<inline>='.']? <val=.prop-val>] }
}

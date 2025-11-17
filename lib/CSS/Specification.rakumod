# a grammar for parsing CSS property specifications in value definition syntax.
# references:
#  http://www.w3.org/TR/CSS21/about.html#property-defs
#  http://dev.w3.org/csswg/css-values/#value-defs
#  https://developer.mozilla.org/en-US/docs/Web/CSS/Value_definition_syntax

grammar CSS::Specification:ver<0.5.0> {
    use CSS::Grammar::CSS3;
    rule TOP { [<def=.property-spec> | <def=.rule-spec> | <def=.func-spec> | ^^ $$ || <.unexpected> ] * }

    rule property-spec {
        :my @*PROP-NAMES = [];
        <prop-names>
            \t <values>
            \t [:i 'n/a' | ua specific | <-[ \t ]>*? properties || $<default>=<-[ \t ]>* ]
            [ \t <-[ \t ]>*? # applies to
              \t [<inherit=.yes>|<inherit=.no>]? ]?
            \t? \N*
    }
    rule rule-spec {
        :my @*PROP-NAMES = [];
        \t? <rule-ref> '=' <values>
    }
    rule func-spec {
        :my @*PROP-NAMES = [];
        \t? <func-ref> '=' <func-proto>
    }
    rule func-proto { <id> '(' ~ ')' <signature=.seq>? }
    token unexpected { \N+ }
    rule values    { <seq> }
    # possibly tab delimited. Assume one synopsis per line.
    token comment {('<!--') .*? ['-->' || <unclosed-comment>]
                  |('/*')   .*? ['*/'  || <unclosed-comment>]}
    token unclosed-comment {$}
    token ws {<!ww>[' '|'\\'\n|<.comment>]*}

    rule yes         {:i yes }
    rule no          {:i no}

    token prop-sep   {<[\x20 \, \*]>+}
    token prop-names {
        [
          [<.quote> <id> <.quote> | <id>]
          { @*PROP-NAMES.push: ~$<id> }
        ] +%% <.prop-sep>
    }
    token id         { <[a..z]>[\w|\-]* }
    token quote      {< ' ‘ ’ >}
    token id-quoted  { <.quote> <id> <.quote> }
    rule keyw        { <id> }
    rule digits      { \d+ }
    rule rule-ref    { '<'~'>' [ <id> [ '['~']' <.domain> +% ',' ]? ] }
    rule func-ref    { '<'~'>' [ <id> '(' ')' ] }
    rule domain      { <[0..9]>+ | '∞' }

    rule seq           { <term=.term-options>+ }
    rule term-options  { <term=.term-combo>    +% '|'  }
    rule term-combo    { <term=.term-required> +% '||' }
    rule term-required { <term=.term-seq>      +% '&&' }
    rule term-seq      { <term>+ }
    rule term          { <value><occurs>? }

    proto token occurs {*}
    token occurs:sym<maybe>       {'?'}
    token occurs:sym<once-plus>   {'+'}
    token occurs:sym<zero-plus>   {'*'}
    token occurs:sym<range>       {<range>}
    token occurs:sym<list>        {'#'<range>?}
    # e.g. <bg-layer>#? , <final-bg-layer>
    token occurs:sym<list-optional>  {'#?' [<.ws> $<trailing>=',']?}
    token range                   {'{'~'}' [ <min=.digits> [',' <max=.digits>]? ] }

    proto rule value {*}
    rule value:sym<func-proto>    { <func-proto> }
    rule value:sym<keywords>      { [<keyw><!before <occurs>>] +% '|' }
    rule value:sym<numbers>       { [<digits><!before <occurs>>] +% '|' }
    rule value:sym<keyw-quant>    { <keyw><occurs> }
    rule value:sym<num-quant>     { <digits><occurs> }
    rule value:sym<group>         { '[' ~ ']' <seq> }
    rule value:sym<func-ref>      { <func-ref> }
    rule value:sym<rule-ref>      { <rule-ref> }
    rule value:sym<op>            { < , / = > }
    rule value:sym<prop-ref>      { <property-ref> }

    proto token property-ref      {*}
    token property-ref:sym<css21> { <id=.id-quoted> }
    token property-ref:sym<css3>  { '<'~'>' <id=.id-quoted> }

}

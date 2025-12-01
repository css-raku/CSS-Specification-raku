# a grammar for parsing CSS property specifications in value definition syntax.
# references:
#  http://www.w3.org/TR/CSS21/about.html#property-defs
#  http://dev.w3.org/csswg/css-values/#value-defs
#  https://developer.mozilla.org/en-US/docs/Web/CSS/Value_definition_syntax
##use Grammar::Debugger;

grammar CSS::Specification:ver<0.5.1> {
    use CSS::Grammar::CSS3;
    rule TOP { [<def=.prop-spec> | <def=.rule-spec> | <def=.func-spec> | ^^ $$ || <.unexpected> ] * }

    rule prop-spec {
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
    # e.g.: example( first , second? , third? )
    rule structured-args {
        [<arg> +% [ ',' ]][',' <optional-arg> +% [ ',' ]]?
        ||  [<optional-arg> *% [ ',' ]]
    }
    rule arg { <value> <!before '?'> }
    rule optional-arg { <value> '?' }
    rule signature { '(' ~ ')' [<args=.structured-args>||<args=.seq>] }
    rule func-proto { <id> <signature> }
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
    rule rule-ref    { '<'~'>' [ <id> [ '['~']' [ <.digits> [ ',' [<.digits>|'∞'] ]? ] ]? ] }
    rule func-ref    { '<'~'>' [ <id> '(' ')' ] }

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

    # stringchar-regular: printable ASCII chars, except: \ ' "
    token stringchar-regular {<[ \x20 \! \# \$ \% \& \(..\[ \]..\~ ]>+ }
    proto token stringchar {*}
    token stringchar:sym<escape>   { <escape> }
    token stringchar:sym<nonascii> { <nonascii> }
    token stringchar:sym<ascii>    { <stringchar-regular>+ }

    token single-quote   {\'}
    token double-quote   {\"}
    proto token string   {*}
    token string:sym<double-q>  { \"[ <stringchar> | <stringchar=.single-quote> ]*\" }
    token string:sym<single-q>  { \'[ <stringchar> | <stringchar=.double-quote> ]*\' }
    token unicode  { (<xdigit>**1..6) <.wc>? }
    # w3c nonascii :== #x80-#xD7FF #xE000-#xFFFD #x10000-#x10FFFF
    token regascii { <[ \x20..\x7F ]> }
    token nonascii { <- [ \x0..\x7F \n ]> }
    token escape   { '\\'[ <char=.unicode> || \n || <char=.regascii> | <char=.nonascii> ] }

    proto rule value {*}
    rule value:sym<func-proto>    { <func-proto> }
    rule value:sym<keywords>      { [<keyw><!before <occurs>>] +% '|' }
    rule value:sym<numbers>       { [<digits><!before <occurs>>] +% '|' }
    rule value:sym<keyw>          { <keyw> }
    rule value:sym<num>           { <digits> }

    rule value:sym<group>         { '[' ~ ']' <seq> }
    rule value:sym<func-ref>      { <func-ref> }
    rule value:sym<rule-ref>      { <rule-ref> }
    rule value:sym<op>            { < , / = > }
    rule value:sym<prop-ref>      { <property-ref> }
    rule value:sym<string>        { <string> }
    rule value:sym<parenthesized> { <signature> }

    proto token property-ref      {*}
    token property-ref:sym<css21> { <id=.id-quoted> }
    token property-ref:sym<css3>  { '<'~'>' <id=.id-quoted> }

}

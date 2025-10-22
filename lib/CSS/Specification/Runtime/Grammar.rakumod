unit grammar CSS::Specification::Runtime::Grammar;

proto rule proforma {*}

token val( $*EXPR, $*USAGE='' ) {
    <proforma> || <rx={$*EXPR}> || <usage>
}

token usage {
    <any-args>
}

# definitions common to CSS1, CSS21 and CSS3 Modules
rule declaration { <decl> <prio>? <any-arg>* <end-decl> || <any-declaration> }
proto rule decl {*}

token length:sym<zero>    {<number> <?{ +$<number> == 0 }> }
token length:sym<percent> {<percentage>}
token angle:sym<zero>     {<number> <?{ +$<number> == 0 }> }
token time:sym<zero>      {<number> <?{ +$<number> == 0 }> }
token frequency:sym<zero> {<number> <?{ +$<number> == 0 }> }

token integer     {$<sign>=< + - >?<uint>}
token number      {<num><!before ['%'|\w]>}
token uri         {<url>}
token keyw        {<id=.Ident>}         # keyword (case insensitive)
token identifier  {<name>}              # identifier (case sensitive)
rule identifiers  {[ <identifier> ]+}   # E.g. font name: Times New Roman

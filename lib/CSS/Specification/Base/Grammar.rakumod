unit role CSS::Specification::Base::Grammar;

proto rule proforma {*}

token val( $*EXPR, $*USAGE='') {
    <proforma> || <rx={$*EXPR}> || <usage($*USAGE)>
}

token inline-function($*NAME, $*EXPR, $*USAGE='') {
    {$*NAME}'(' [ <args={$*EXPR}> || <usage($*USAGE)> ] ')'
}

token usage($*USAGE) {
    <any-args>
}

# definitions common to all modules
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
multi token keyw  {   <id=.Ident>          # keyword (case insensitive)
                  ||  $<id>=[:i <[0..9]>*?<[a..z]><[a..z0..9_-]>*] # e.g. 0deg
                  }
multi token keyw($rx) {<id={$rx}>}      # keyword (case insensitive)
token identifier  {<name>}              # identifier (case sensitive)
rule identifiers  {[ <identifier> ]+}   # E.g. font name: Times New Roman
rule custom-ident{ <?before '--'><identifier> }

use CSS::Aural::Spec::Grammar;
use CSS::Aural::Spec::Interface;
use CSS::Grammar::CSS21;
use CSS::Specification::_Base;

grammar CSS::Aural::Grammar
    is CSS::Aural::Spec::Grammar 
    is CSS::Grammar::CSS21
    is CSS::Specification::_Base
    does CSS::Aural::Spec::Interface {

    rule module-declaration:sym<test> { <.ws>? <decl> <prio>? <any-arg>* <end-decl> }
    proto rule decl {*}

    token keyw        {<ident>}             # keyword (case insensitive)
    token identifier  {<name>}              # identifier (case sensitive)
    token number      {<num> <!before ['%'|\w]>}
    token uri         {<url>}

    rule generic-voice  {:i [ male | female | child ] & <keyw> }
    rule specific-voice {:i <identifier> | <string> }
}

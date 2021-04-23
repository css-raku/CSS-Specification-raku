
use Test::CSS::Aural::Spec::Grammar;
use Test::CSS::Aural::Spec::Interface;
use CSS::Specification::Defs;
use CSS::Grammar::CSS21;

grammar Test::CSS::Aural::Grammar
    is Test::CSS::Aural::Spec::Grammar 
    is CSS::Specification::Defs
    is CSS::Grammar::CSS21
    does Test::CSS::Aural::Spec::Interface {

    rule proforma:sym<inherit> { <sym> }
}

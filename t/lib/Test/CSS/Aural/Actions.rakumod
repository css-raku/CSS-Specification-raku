use v6;
use Test::CSS::Aural::Spec::Actions;
use Test::CSS::Aural::Spec::Interface;
use CSS::Compiler::Runtime::BaseActions;
use CSS::Grammar::Actions;

class Test::CSS::Aural::Actions
    is Test::CSS::Aural::Spec::Actions
    is CSS::Compiler::Runtime::BaseActions
    is CSS::Grammar::Actions
    does Test::CSS::Aural::Spec::Interface {

    method proforma:sym<inherit>($/) { make {'keyw' => ~$<sym>} }
}

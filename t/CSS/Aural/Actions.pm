use v6;
use CSS::Aural::Spec::Actions;
use CSS::Grammar::Actions;
use CSS::Specification::_Base::Actions;
use CSS::Aural::Spec::Interface;

class CSS::Aural::Actions
    is CSS::Aural::Spec::Actions
    is CSS::Grammar::Actions
    is CSS::Specification::_Base::Actions
    does CSS::Aural::Spec::Interface {

    method proforma:sym<inherit>($/) { make {~$<sym> => True} }

    method declaration($/) { make $.decl( $<decl> ) }
    method keyw($/)        { make $<Ident>.ast }
    method identifier($/)  { make $<name>.ast }
    method number($/)      { make $<num>.ast }
    method uri($/)         { make $<url>.ast }

    method generic-voice($/) { make $.list($/) }
    method specific-voice($/) { make $.list($/) }
}

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

    method proforma:sym<inherit>($/) { make {'keyw' => ~$<sym>} }

    method declaration($/) { make $.decl( $<decl> ) }
    method keyw($/)        { make $.token( $<Ident>.ast, :type<keyw> ) }
    method identifier($/)  { make $.token( $<name>.ast, :type<ident> ) }
    method number($/)      { make $.token( $<num>.ast, :type<num> ) }
    method uri($/)         { make $.token( $<url>.ast, :type<url> ) }

    method generic-voice($/)  { make $<keyw>.ast }
    method specific-voice($/) { make $<voice>.ast }
}

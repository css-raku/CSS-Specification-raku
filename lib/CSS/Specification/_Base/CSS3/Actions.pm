use v6;

use CSS::Specification::_Base::Actions;

class CSS::Specification::_Base::CSS3::Actions
    is CSS::Specification::_Base::Actions {
    has @._proforma = 'inherit', 'initial';

    method resolution:sym<dim>($/)        { make $.token($<num>.ast, :type($0.lc) ) }
    method dimension:sym<resolution>($/)  { make $<resolution>.ast }
}

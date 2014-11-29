use v6;

class CSS::Specification::_Base::Actions {

    use CSS::Grammar::AST :CSSTrait;

    has @._proforma;

    method decl($/, :@proforma = @._proforma ) {

        my %ast;

        %ast<ident> = $0.trim.lc
            if $0;

        if $<val> {
            my $val = $<val>.ast;

            if $val<usage> {
                my $synopsis := $val<usage>;
                $.warning( ('usage ' ~ $synopsis, @proforma).join: ' | ');
                return Any;
            }
            elsif ! $val<expr> {
                $.warning('dropping declaration', %ast<ident>);
                return Any;
            }

            %ast<expr> = $val<expr>;
        }

        return %ast;
    }

    method val($/) {
        my %ast;

        if $<usage> {
            %ast<usage> = $<usage>.ast;
        }
        elsif $<proforma> {
            my $expr = $<proforma>.ast;
            %ast<expr> = [$expr]
                if $expr;
        }
        else {
            my $m = $<rx><expr>;
            unless $m &&
                ($m.can('caps') && (!$m.caps || $m.caps.grep({! .value.ast.defined}))) {
                    my $expr-ast = $.list($m);
                    $expr-ast = $.token( $expr-ast, :trait(CSSTrait::Box))
                        if $*BOXED;

                    %ast<expr> = $expr-ast;
            }
        }

        make %ast;
    }

    method usage($/) {
        make ~ $*USAGE;
    }

    method op($/) {
        make $/.lc
    }

}

use v6;

class CSS::Specification::_Base::Actions {

    use CSS::Grammar::AST :CSSTrait;

    has @._proforma;

    method decl($/, :@proforma = @._proforma ) {

        my %ast;

        %ast<property> = $0.trim.lc
            if $0;

        if $<val> {
            my $val = $<val>.ast;

            if $val<usage> {
                my $synopsis := $val<usage>;
                $.warning( ('usage ' ~ $synopsis, @proforma).join: ' | ');
                return Any;
            }
            elsif ! $val<expr> {
                $.warning('dropping declaration', %ast<property>);
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
                    my $trait = CSSTrait::Box
                        if $*BOXED;

                    %ast<expr> = $.token( $.list($m), :$trait);
            }
        }

        make %ast;
    }

    method usage($/) {
        make ~ $*USAGE;
    }

}

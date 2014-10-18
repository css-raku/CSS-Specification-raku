use v6;

class CSS::Specification::_Base::Actions {

    has @._proforma;

    method decl($/, @proforma = @._proforma) {

	my $property = (~$0).trim.lc;
        my $expr;

        if $<val> {
            my $val-ast = $<val>.ast;

            if $val-ast<usage> {
                my $synopsis := $val-ast<usage>;
                $.warning( ('usage ' ~ $synopsis, @proforma).join: ' | ');
                return Any;
            }
            elsif ! $val-ast<expr> {
                $.warning('dropping declaration', $property);
                return Any;
            }

            $expr = $val-ast<expr>;
        }

        my %ast;

        if $<val> && $<val><boxed> {
            #  expand to a list of properties. eg: margin => margin-top,
            #      margin-right margin-bottom margin-left
            warn "too many arguments: @expr"
                if @$expr > 4;
            constant @Edges = <top right bottom left>;
            my %box = @Edges Z=> @$expr;
            %box<right>  //= %box<top>;
            %box<bottom> //= %box<top>;
            %box<left>   //= %box<right>;

            my @properties = @Edges.map: -> $edge {
                my $prop = $property ~ '-' ~ $edge;
                my $val = %box{$edge};
                {property => $prop, expr => [$val]}
            }
            %ast<property-list> = @properties;
        }
        else {
            %ast<property> = $property;
            %ast<expr> = $expr
                if $expr;
        }

        return %ast;
    }

    method val($/) {
        my %ast;

        if $<usage> {
            %ast<usage> = $<usage>.ast;
        }
        elsif $<proforma> {
            %ast<expr> = [$<proforma>.ast];
        }
        else {
            my $m = $<rx><expr>;
            unless $m &&
                ($m.can('caps') && (!$m.caps || $m.caps.grep({! .value.ast.defined}))) {
                    %ast<expr> = @( $.list($m) );
            }
        }

        make %ast;
    }

    method usage($/) {
        make ~ $*USAGE;
    }

}

use v6;

class CSS::Specification::_Base::Actions {

    has @._proforma;

    method decl($/, @proforma = @._proforma) {

	my $property = (~$0).trim.lc;

        my @expr;

        if $<val><usage> {
            my $synopsis := $<val><usage>.ast.subst(/^ .*? ':' /, $property ~ ':'),;
            $.warning( ('usage ' ~ $synopsis, @proforma).join: ' | ');
            return Any;
        }
        elsif $<val><proforma> {
            @expr = ($<val><proforma>.ast);
        }
        else {
            my $m = $<val><rx><expr>;
            if $m &&
                ($m.can('caps') && (!$m.caps || $m.caps.grep({! .value.ast.defined}))) {
                    $.warning('dropping declaration', $property);
                    return Any;
            }
            @expr = @( $.list($m) );
         }

        my %ast;

        if $<val><boxed> {
            #  expand to a list of properties. eg: margin => margin-top,
            #      margin-right margin-bottom margin-left
            warn "too many arguments: @expr"
                if @expr > 4;
            constant @Edges = <top right bottom left>;
            my %box = @Edges Z=> @expr;
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
            %ast<expr> = @expr
                if @expr;
        }

        return %ast;
    }

    method usage($/) {
        make ~ $*USAGE;
    }

}

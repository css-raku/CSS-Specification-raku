use v6;

class CSS::Specification::_Base::Actions {

    has @._proforma;

    method decl($/, @proforma = @._proforma) {

	my $property = (~$0).trim.lc;

        my @expr;

        if $*USAGE {
            my $synopsis := $*USAGE.subst(/^ .*? ':' /, $property ~ ':'),;
            $.warning( ('usage ' ~ $synopsis, @proforma).join: ' | ');
            return Any;
        }
        elsif $<proforma> {
            @expr = ($<proforma>.ast);
        }
        elsif $<expr> {
            my $m = $<expr>;
            if $m &&
                ($m.can('caps') && (!$m.caps || $m.caps.grep({! .value.ast.defined}))) {
                    $.warning('dropping declaration', $property);
                    return Any;
            }
            @expr = @( $.list($m) );
         }

        my %ast;

        if $<boxed> {
            #  expand to a list of properties. eg: margin => margin-top,
            #      margin-right margin-bottom margin-left
            warn "too many arguments: @expr"
                if @expr > 4;
            constant @Edges = <top right bottom left>;
            my %box = @Edges Z=> @expr;
            %box<right>  //= %box<top>;
            %box<bottom> //= %box<top>;
            %box<left>   //= %box<right>;

            my @properties;
            for @Edges -> $edge {
                my $prop = $property ~ '-' ~ $edge;
                my $val = %box{$edge};
                @properties.push( {property => $prop, expr => [$val]} );
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

}

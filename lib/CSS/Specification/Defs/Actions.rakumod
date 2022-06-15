use v6;

class CSS::Specification::Defs::Actions {

    use CSS::Grammar::Defs :CSSValue;
    use CSS::Specification::AST;

    method build { CSS::Specification::AST }

    method val($/) {
        my %ast;

        with $<usage> {
            %ast<usage> = .ast;
        }
        else {
            with $<proforma> {
                %ast<expr> = [.ast]
            }
            else {
                with $<rx><expr> {
                    %ast<expr> = $.build.list($_)
                        unless .can('caps') && (!.caps || .caps.first({! .value.ast.defined}));
                }
            }
        }

        make %ast;
    }

    method usage($/) {
        make ~ $*USAGE;
    }

    # ---- CSS::Grammar overrides ---- #

    method any-function($/)             {
	##        nextsame if $.lax;
	if $.lax {
	    $<any-args>
	        ?? $.warning('skipping function arguments', ~$<any-args>)
		!! make $.build.node($/);
	}
        else {
            $.warning('ignoring function', $<Ident>.ast.lc);
        }
    }

    multi method declaration($/ where $<any-declaration>)  {
        with $<any-declaration>.ast -> $ast {
            my ($key, $value) = $ast.kv;
            if $.lax {
                make $key => $value;
            }
            else {
                $.warning('dropping unknown property',
                          $value<at-keyw> ?? '@'~$value<at-keyw> !! $value<ident>);
            }
        }
    }
    multi method declaration($/)  {
        my %ast = %( $.build.decl($<decl>, :obj(self)) )
           || return;

        if $<any-arg> {
            return $.warning("extra terms following '{%ast<ident>}' declaration",
                             ~$<any-arg>, 'dropped');
        }

        if $<prio> && (my $prio = $<prio>.ast) {
            %ast ,= :$prio;
        }
        make $.build.token( %ast, :type(CSSValue::Property) );
    }

    method proforma:sym<inherit>($/) { make (:keyw<inherit>) }
    method proforma:sym<initial>($/) { make (:keyw<initial>) }

    #---- Language Extensions ----#

    method length:sym<zero>($/) {
        make $.build.token(0, :type<px>)
    }

    method length:sym<percent>($/) {
        make $<percentage>.ast;
    }

    method angle:sym<zero>($/) {
        make $.build.token(0, :type<deg>)
    }

    method time:sym<zero>($/) {
        make $.build.token(0, :type<s>)
    }

    method frequency:sym<zero>($/) {
        make $.build.token(0, :type<hz>)
    }

    use Color::Names::CSS3 :colors;
    my constant %Colors = do {
        my %v;
        for COLORS.pairs {
            my (Str $name, Hash $val) = .kv;
            my List $rgb = $val<rgb>;
            %v{$name} = $rgb;
            with $name.index("gray") {
                $name.substr-rw($_, 4) = 'grey';
                %v{$name} = $rgb;
            }
        }
        %v;
    }
    method colors { %Colors }

    method color:sym<named>($/) {
        my Str $color-name = $<keyw>.ast.value;
        my @rgb = @( $.colors{$color-name} )
            or die "unknown color: " ~ $color-name;

        my @color = @rgb.map: { (CSSValue::NumberComponent) => $_ };

        make $.build.token(@color, :type<rgb>);
    }

    method integer($/)     {
        my Int $val = $<uint>.ast;
        $val = -$val
            if $<sign> && $<sign> eq '-';
        make $.build.token($val, :type(CSSValue::IntegerComponent))
    }

    method number($/)      { make $.build.token($<num>.ast, :type(CSSValue::NumberComponent)) }
    method uri($/)         { make $<url>.ast }
    method keyw($/)        { make $.build.token($<id>.lc, :type(CSSValue::KeywordComponent)) }
    # case sensitive identifiers
    method identifier($/)  { make $.build.token($<name>.ast, :type(CSSValue::IdentifierComponent)) }
    # identifiers strung-together, e.g New Century Schoolbook
    method identifiers($/) { make $.build.token( $<identifier>.map({ .ast.value }).join(' '), :type(CSSValue::IdentifierComponent)) }
}

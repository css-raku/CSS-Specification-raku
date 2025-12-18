unit role CSS::Specification::Base::Actions;

use CSS::Grammar::Defs :CSSValue;
use CSS::Grammar::AST;

method build { CSS::Grammar::AST }

multi method val($/ where $<rx>) {
    make $.build.rule($<rx>);
}
multi method val($/ where $<usage>) {
    make 'usage' => $<usage>.ast
}
multi method val($/ where $<proforma>) {
    make 'expr' => [ $<proforma>.ast ]
}

method usage($/) {
    make ~ $*USAGE;
}

multi method make-func($, $/ where $<usage>) {
    $.warning('usage: ' ~ $<usage>.ast)
}
multi method make-func($name, $/, |c) {
    make $.build.func: $name, $.build.list($/), |c;
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
        my :($key, $value) := $ast.kv;
        if $.lax {
            make $key => $value;
        }
        else {
            $.warning('dropping unknown property',
                      $value<at-keyw> ?? '@'~$value<at-keyw> !! $value<ident>);
        }
    }
}
multi method declaration($/ where $<any-arg>) {
    $.warning(
        "extra terms following declaration '{$<decl>.trim}'",
        ~"'$<any-arg>'", 'dropped'
    );
}
multi method declaration(::?CLASS:D $obj: $/)  {
    my %ast = %( $.build.decl($<decl>, :$obj) )
       || return;

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
        $name .= substr(0, $_) with $name.index('-');
        my List $rgb = $val<rgb>;
        %v{$name} = $rgb;
        if $name.contains("gray") {
            %v{ $name.subst('gray', 'grey') } = $rgb;
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


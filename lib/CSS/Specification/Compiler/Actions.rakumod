unit class CSS::Specification::Compiler::Actions;

# these actions translate a CSS property specification to Raku
# rules or actions.
has %.rule-refs is rw;
has %.props is rw;
has %.rules is rw;
has %.child-props is rw;

method TOP($/) { make $<def>>>.ast };

method property-spec($/) {
    my @props = @($<prop-names>.ast);
    %.props{$_}++ for @props;

    my $spec = $<spec>.ast;
    my $synopsis = ~$<spec>;

    my %prop-def = (:@props, :$synopsis, :$spec);

    %prop-def<inherit> = .ast with $<inherit>;

    %prop-def<default> = ~$_
        with $<default>;

    make %prop-def;
}

method rule-spec($/) {

    my $rule = $<rule>.ast,
    my $raku-ast = $<spec>.ast;
    my $synopsis = ~$<spec>;
    %.props{$rule}++;

    my %rule-def = (
        :$rule, :$synopsis, :$raku-ast
        );

    make %rule-def;
}

method yes($/) { make True }
method no($/)  { make False }

method spec($/) {
    my $spec = $<seq>.ast;
    make $spec;
}

method prop-names($/) {
    my @prop-names = $<id>>>.ast;
    make @prop-names;
}

method id($/)        { make ~$/ }
method id-quoted($/) { make $<id>.ast }
method keyw($/)      { make 'keyw' => ~$<id> }
method digits($/)    { make 'num' => $/.Int }
method rule($/)      { make $<id>.ast }

method seq($/) {
    my @seq = @<term>>>.ast;
    make @seq == 1 ?? @seq[0] !! (:@seq);
}

method term-options($/) {
    my @alt = @<term>>>.ast;
    make @alt == 1 ?? @alt[0] !! :@alt;
}

method term-combo($/) {
    my @combo = @<term>>>.ast;
    make @combo == 1 ?? @combo[0] !! (:@combo)
}

method term-required($/) {
    my @required = $<term>>>.ast;
    make @required == 1 ?? @required[0] !! (:@required);
}

method term-seq($/) {
    my @seq = @<term>>>.ast;
    make @seq == 1
        ?? @seq[0]
        !! (:@seq);
}

method term($/) {
    my $value = $<value>.ast;

    make $<occurs>
        ?? :occurs[$<occurs>.ast, $value]
        !! $value;
}

method occurs:sym<maybe>($/)     { make '?' }
method occurs:sym<once-plus>($/) is DEPRECATED { make '+' }
method occurs:sym<zero-plus>($/) { make '*' }
method occurs:sym<list>($/) {
    with $<range> {
        given .ast {
            make ['list', .[1],  .[2] ];
        }
    }
    else {
        make 'list';
    }
}
method occurs:sym<range>($/)     { make $<range>.ast }
method range($/) {
    my @seq = 'seq', $<min>.ast.value, ($<max> // $<min>).ast.value;
    make @seq;
}

method value:sym<func>($/) {
    # todo - save function prototype
    my $rule = $<id>.ast;
    %.rule-refs{ $rule }++;
    make (:$rule);
}

method value:sym<keywords>($/) {
    my @keywords = @<keyw>.map: {.ast.value};
    make (:@keywords);
}

method value:sym<keyw-quant>($/) {
    make 'occurs' => [$<occurs>.ast, $<keyw>.ast];
}

method value:sym<numbers>($/) {
    my @numbers = @<digits>.map: {.ast.value};
    make (:@numbers);
}

method value:sym<num-quant>($/) {
    make 'occurs' => [$<occurs>.ast, $<digits>.ast];
}

method value:sym<group>($/) {
    my $group = $<seq>.ast;
    make (:$group);
}

method value:sym<rule>($/) {
    my $rule = ~$<rule>.ast;
    %.rule-refs{ $rule }++;
    make (:$rule);
}

method value:sym<op>($/) { my $op = $/.trim; make (:$op); }

method property-ref:sym<css21>($/) { make $<id>.ast }
method property-ref:sym<css3>($/) { make $<id>.ast }
method value:sym<prop-ref>($/)        {
    my $prop-ref = $<property-ref>.ast;
    my $rule = 'expr-' ~ $prop-ref;
    %.rule-refs{ $rule; }++;
    %.child-props{$_}.push: $prop-ref for @*PROP-NAMES;
    make (:$rule);
}

method value:sym<literal>($/)  { make 'string' => ~$0 }

method value:sym<num>($/)      { make 'num' => $/.Int }

method value:sym<keyw>($/)     { make 'ident' => ~$/ }


unit class CSS::Specification::Compiler::Actions;

# these actions translate a CSS property specification to Raku
# rules or actions.
has %.prop-refs is rw;
has %.props is rw;
has %.rules is rw;
has %.child-props is rw;

method TOP($/) is DEPRECATED { make $<def>>>.ast };

method property-spec($/) is DEPRECATED {
    my @props = @($<prop-names>.ast);
    %.props{$_}++ for @props;

    my $spec = $<spec>.ast;

    my %prop-def = (
        props    => @props,
        synopsis => ~$<spec>,
        raku    => $spec,
        );

    %prop-def<inherit> = .ast with $<inherit>;

    %prop-def<default> = ~$_
        with $<default>;

    make %prop-def;
}

method rule-spec($/) is DEPRECATED {

    my $rule = $<rule>.ast,
    my $raku = $<spec>.ast;
    my $synopsis = ~$<spec>;
    %.props{$rule}++;

    my %rule-def = (
        :$rule, :$synopsis, :$raku
        );

    make %rule-def;
}

method yes($/) is DEPRECATED { make True }
method no($/)  { make False }

method spec($/) {
    my $spec = $<terms>.ast;
    warn "todo CHOICE" if $*CHOICE;
##    $spec = ':my @*SEEN; ' ~ $spec
##        if $*CHOICE;

    make $spec;
}

method prop-names($/) {
    my @prop-names = $<id>>>.ast;
    make @prop-names;
}

method id($/)        { make ~$/ }
method id-quoted($/) is DEPRECATED { make $<id>.ast }
method keyw($/)      { make 'keyw' => ~$<id> }
method digits($/)    { make 'num' => $/.Int }
method rule($/)      { make $<id>.ast }

method terms($/) {
    my @terms = @<term>>>.ast;
    make @terms == 1
         ?? @terms[0]
         !! ('terms' => @terms);
}

method term-options($/) {
    my @alt = @<term>>>.ast;
    make @alt == 1
        ?? @alt[0]
        !! :@alt;
}

method term-combo($/) {
    my @choices = @<term>>>.ast;

    make @choices == 1
        ?? @choices[0]
        !! ('combo' => @choices)
}

method term-required($/) {
    my @choices = $<term>>>.ast;

    make @choices == 1
        ?? @choices[0]
        !! [~] ('required' => @choices)
}

method term-values($/) {
    make @<term> == 1
        ?? @<term>[0].ast
        !! ('values' => @<term>>>.ast);
}

method term($/) {
    my $value = $<value>.ast;

    make $<occurs>
        ?? :occurs[$<occurs>.ast, $value]
        !! $value;
}

method occurs:sym<maybe>($/)     { make '?' }
method occurs:sym<once-plus>($/) is DEPRECATED { make '+' }
method occurs:sym<zero-plus>($/) is DEPRECATED { make '*' }
method occurs:sym<list>($/) is DEPRECATED {
    my $quant = $<range> ?? $<range>.ast !! '+';
    make "{$quant}% <op(',')>"
}
method occurs:sym<range>($/)     { make $<range>.ast }
method range($/) {
    my @range = $<min>.ast.value, ($<max> // $<min>).ast.value;
    make @range;
}

method value:sym<func>($/) is DEPRECATED {
    # todo - save function prototype
    %.prop-refs{ ~$<id>.ast }++;
    make [~] '<', $<id>.ast, '>';
}

method value:sym<keywords>($/) {
    make 'keywords' => @<keyw>.map: {.ast.value};
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

method value:sym<group>($/) is DEPRECATED {
    my $val = $<terms>.ast;
    make [~] '[ ', $val, ' ]';
}

method value:sym<rule>($/) {
    my $rule = ~$<rule>.ast;
    %.prop-refs{ $rule }++;
    make (:$rule);
}

method value:sym<op>($/) is DEPRECATED { make [~] "<op('", $/.trim, "')>" }

method property-ref:sym<css21>($/) is DEPRECATED { make $<id>.ast }
method property-ref:sym<css3>($/) is DEPRECATED { make $<id>.ast }
method value:sym<prop-ref>($/)        {
    my $prop-ref = $<property-ref>.ast;
    %.prop-refs{ 'expr-' ~ $prop-ref }++;
    %.child-props{$_}.push: $prop-ref for @*PROP-NAMES; 
    make [~] '<expr-', $prop-ref, '>';
}

method value:sym<literal>($/)  { make 'string' => ~$0 }

method value:sym<num>($/)      { make 'num' => $/.Int }

method value:sym<keyw>($/)     { make 'ident' => ~$/ }


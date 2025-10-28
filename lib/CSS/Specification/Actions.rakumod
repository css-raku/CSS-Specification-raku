unit class CSS::Specification::Actions;

use Method::Also;

# these actions translate a CSS property specification to an
# intermediate AST
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
    my $spec = $<spec>.ast;
    my $synopsis = ~$<spec>;
    %.props{$rule}++;

    my %rule-def = (
        :$rule, :$synopsis, :$spec
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

method !make-term($/, $name) {
    my @term =  @<term>>>.ast;
    make @term == 1 ?? @term[0] !! ($name => @term);
}

method seq($/) is also<term-seq> {
    self!make-term: $/, 'seq';
}

method term-options($/) {
    self!make-term: $/, 'alt';
}

method term-combo($/) {
    self!make-term: $/, 'combo';
}

method term-required($/) {
    self!make-term: $/, 'required';
}

method term($/) {
    my $value = $<value>.ast;

    make $<occurs>
        ?? :occurs[$<occurs>.ast, $value]
        !! $value;
}

method occurs:sym<maybe>($/)     { make '?' }
method occurs:sym<once-plus>($/) { make '+' }
method occurs:sym<zero-plus>($/) { make '*' }
method occurs:sym<list>($/) {
    make $<range>
        ?? $<range>.ast.clone.append: ','
        !! ','
}
method occurs:sym<range>($/)     { make $<range>.ast }
method range($/) {
    my $min = $<min>.ast.value;
    my $max = do with $<max> { .ast.value } else { $min };
    make [$min, $max];
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

method property-ref:sym<css21>($/) { make 'ref' => $<id>.ast }
method property-ref:sym<css3>($/) { make 'ref' => $<id>.ast }
method value:sym<prop-ref>($/)        {
    my Pair $prop-ref = $<property-ref>.ast;
    my $prop =  $prop-ref.value;
    my $rule = 'expr-' ~ $prop;;
    %.rule-refs{ $rule }++;
    %.child-props{$_}.push: $prop for @*PROP-NAMES;
    make (:$rule);
}

method value:sym<literal>($/)  { make 'string' => ~$0 }

method value:sym<num>($/)      { make 'num' => $/.Int }

method value:sym<keyw>($/)     { make 'ident' => ~$/ }


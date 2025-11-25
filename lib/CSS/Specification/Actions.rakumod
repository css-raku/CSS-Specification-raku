unit class CSS::Specification::Actions;

use Method::Also;

# these actions translate a CSS property specification to an
# intermediate AST
has %.rules is rw;
has %.rule-refs is rw;
has %.funcs is rw;
has %.protos is rw;
has %.func-refs is rw;
has %.props is rw;
has %.child-props is rw;

method !check-symbols {
    my %ruleish = %!rules, %!rule-refs;
    for %ruleish.keys.sort {
        warn "$_ used as both a rule and a function"
            if %!funcs{$_} || %!func-refs{$_};
    }
}
method TOP($/) {
    self!check-symbols;
    make @<def>>>.ast;
};

method property-spec($/) {
    my @props = @($<prop-names>.ast);
    %.props{$_}++ for @props;

    my $spec = $<values>.ast;
    my $synopsis = ~$<values>;

    my %prop-def = :@props, :$spec, :$synopsis;

    %prop-def<inherit> = .ast with $<inherit>;

    %prop-def<default> = ~$_
        with $<default>;

    make %prop-def;
}

method rule-spec($/) {
    my $rule = $<rule-ref>.ast,
    my $spec = $<values>.ast;
    my $synopsis = ~$<values>;
    %!rules{$rule}++;

    my %rule-def = (
        :$rule, :$synopsis, :$spec
        );

    make %rule-def;
}

method func-spec($/) {
    my $func = $<func-ref>.ast,
    my $proto = $<func-proto>.ast<proto>;
    my $synopsis = ~$<func-proto>;
    my $signature = $proto<signature>;

    my %func-spec = (
        :$func, :$signature, :$synopsis,
        );

    %!funcs{$func}++;
    make (:%func-spec);
}

method group($/) {
    make $<seq>.ast;
}

method func-proto($/) {
    my $synopsis = $/.trim;
    my $func = $<id>.ast;
    my %proto = :$func, :$synopsis;
    %proto<signature> = .ast with $<signature>;

    with %!protos{$func} {
       warn "inconsistant function declaration: {$synopsis.raku} vs {.<synopsis>.raku}"
           unless .<signature> eqv %proto<signature>;
    }
    else {
        $_ = %proto;
    }

    make (:%proto);
}

method yes($/) { make True }
method no($/)  { make False }

method values($/) {
    make $<seq>.ast;
}

method prop-names($/) {
    my @prop-names = $<id>>>.ast;
    make @prop-names;
}

method unexpected($/) is hidden-from-backtrace {
    die "Unexpected input: " ~$/;
}

method id($/)        { make ~$/ }
method id-quoted($/) { make $<id>.ast }
method keyw($/)      { make 'keyw' => ~$<id> }
method digits($/)    { make 'num' => $/.Int }
method rule-ref($/)  { make $<id>.ast }
method func-ref($/)  { make $<id>.ast }

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
method occurs:sym<list-optional>($/) {
    my $trailing = $<trailing>.so;
    make ['*', ',', :$trailing ]
}
method occurs:sym<range>($/)     { make $<range>.ast }
method range($/) {
    my $min = $<min>.ast.value;
    my $max = do with $<max> { .ast.value } else { $min };
    make [$min, $max];
}

method stringchar:sym<escape>($/)   { make $<escape>.ast }
method stringchar:sym<nonascii>($/) { make $<nonascii>.ast }
method stringchar:sym<ascii>($/)    { make ~$/ }
method !to-unicode($hex-str --> Str) {
    my $char  = chr( :16($hex-str) );
    CATCH {
        default {
            $.warning('invalid unicode code-point', 'U+' ~ $hex-str.uc );
            $char = chr(0xFFFD); # �
        }
    }
    $char;
}

method unicode($/)  { make self!to-unicode(~$0) }

method regascii($/) { make ~$/ }
method nonascii($/) { make ~$/ }

method escape($/)   { make do with $<char> { .ast } else { '' } }

method single-quote($/) { make "'" }
method double-quote($/) { make '"' }

method !string-token($/) {
    make [~] $<stringchar>>>.ast;
}

proto method string {*}
method string:sym<single-q>($/) { self!string-token($/) }

method string:sym<double-q>($/) { self!string-token($/) }

method value:sym<keywords>($/) {
    my @keywords = @<keyw>.map: {.ast.value};
    make (:@keywords);
}

method value:sym<numbers>($/) {
    my @numbers = @<digits>.map: {.ast.value};
    make (:@numbers);
}

method value:sym<keyw>($/) {
    make $<keyw>.ast;
}

method value:sym<num>($/) {
    make $<digits>.ast;
}

method value:sym<group>($/) {
    my $group = $<seq>.ast;
    make (:$group);
}

method value:sym<rule-ref>($/) {
    my $rule = ~$<rule-ref>.ast;
    %!rule-refs{ $rule }++;
    make (:$rule);
}

method value:sym<func-ref>($/) {
    my $func = ~$<func-ref>.ast;
    %!func-refs{ $func }++;
    make (:$func);
}

method value:sym<func-proto>($/) {
    my $func = ~$<func-proto>.ast<proto><func>;
    # todo process prototypes
    %!func-refs{ $func }++;
    make (:$func);
}

method value:sym<op>($/) { my $op = $/.trim; make (:$op); }

method property-ref:sym<css21>($/) { make 'ref' => $<id>.ast }
method property-ref:sym<css3>($/) { make 'ref' => $<id>.ast }
method value:sym<prop-ref>($/)        {
    my Pair $prop-ref = $<property-ref>.ast;
    my $prop =  $prop-ref.value;
    my $rule = 'prop-val-' ~ $prop;;
    %!rule-refs{ $rule }++;
    %!child-props{$_}.push: $prop for @*PROP-NAMES;
    make (:$rule);
}

method value:sym<string>($/)  { make 'op' => $<string>.ast }
method value:sym<parenthesized>($/)  {
    my @seq = $<group>.ast;
    make (:@seq);
}


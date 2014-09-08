use v6;

class CSS::Specification::Actions {

    # these actions translate a CSS property specification to Perl 6
    # rules or actions.
    has %.prop-refs is rw;
    has %.props is rw;

    method TOP($/) { make $<property-spec>>>.ast };

    # condensation eg: 'border-top-style' ... 'border-left-style' 
    # ==> pfx='border' props=<top right bottom left> sfx='-style'

    method property-spec($/) {
        my @props = @($<prop-names>.ast);

        my $terms = $<terms>.ast;

        my %prop-def = (
            props    => @props,
            synopsis => ~$<terms>,
            perl6    => $terms,
            );

        make %prop-def;
    }

    method prop-names($/) {
        my @prop-names = $<id>>>.ast;
        %.props{$_}++ for @prop-names;
        make @prop-names;
    }

    method id($/)        { make ~$/ }
    method id-quoted($/) { make $<id>.ast }
    method keyw($/)      { make $<id>.subst(/\-/, '\-'):g }
    method digits($/)    { make $/.Int }

    method values($/) {
        make @<term>>>.ast.join(' ');
    }
    method term($/) {
        my $value = $<value>.ast;
        $value ~= $<occurs>.ast
            if $<occurs>;

        make $value;
    }

    method terms($/) {
        make @<term>>>.ast.join(' ');
    }

    method options($/) {
        my @choices = @<term>>>.ast;
        return make @choices[0]
            unless @choices > 1;
        
        make '[ ' ~ @choices.join(' | ') ~ ' ]';
    }

    method _choose(@choices) {
        my $n = 0;
        return '[:my @*SEEN; ' ~ @choices.map({[~] ($_, ' <!seen(', $n++, ')>')}).join(' | ') ~ ' ]';
    }

    method combo($/) {
        my @choices = @<term>>>.ast;
        return make @choices[0]
            unless @choices > 1;
        make $._choose( @choices ) ~ '+';
    }

    method required($/) {
        my @choices = $<term>>>.ast;
        return make @choices[0]
            unless @choices > 1;
        make $._choose( @choices ) ~ '**' ~ @choices.Int
    }

    method occurs:sym<maybe>($/)     { make '?' }
    method occurs:sym<once-plus>($/) { make '+' }
    method occurs:sym<zero-plus>($/) { make '*' }
    method occurs:sym<list>($/)      { make " +% ','" }
    method occurs:sym<range>($/) {
        make '**' ~ $<min>.ast ~ '..' ~ $<max>.ast;
    }

    method value:sym<func>($/)     {
        # todo - save function prototype
        make '<' ~ $<id>.ast ~ '>';
    }

    method value:sym<keywords>($/) {
        my $keywords = @<keyw> > 1
            ?? '[ ' ~ @<keyw>>>.ast.join(' | ') ~ ' ]'
            !! @<keyw>[0].ast;

        make $keywords ~ ' & <keyw>';
    }

    method value:sym<keyw-quant>($/) {
        make '[ ' ~ $<keyw>.ast ~ ' & <keyw> ]' ~ $<occurs>.ast
    }

    method value:sym<numbers>($/) {
        my $keywords = @<digits> > 1
            ?? '[ ' ~ @<digits>>>.ast.join(' | ') ~ ' ]'
            !! @<digits>[0].ast;

        make $keywords ~ ' & <number>';
    }

    method value:sym<num-quant>($/) {
        make '[ ' ~ $<digits>.ast ~ ' & <number> ]' ~ $<occurs>.ast
    }

    method value:sym<group>($/) {
        my $val = $<terms>.ast;
        make '[ ' ~ $val ~ ' ]';
    }

    method value:sym<rule>($/)     {
        %.prop-refs{ ~$<id> }++;
        make '<' ~ $<id>.ast ~ '>'
    }

    method value:sym<punc>($/)     { make "'" ~ (~$/).trim ~ "'" }

    method property-ref:sym<css21>($/) { make $<id>.ast }
    method property-ref:sym<css3>($/)  { make $<id>.ast }
    method value:sym<prop-ref>($/)        {
        my $prop-ref = $<property-ref>.ast;
        %.prop-refs{ 'expr-' ~ $prop-ref }++;
        make '<expr-' ~ $prop-ref ~ '>';
    }

    method value:sym<literal>($/)  { make "'" ~ ~$0 ~ "'"}
            
    method value:sym<num>($/)      { make ~$/ }

    method value:sym<keyw>($/)     { make ~$/ }
}

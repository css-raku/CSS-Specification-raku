unit module CSS::Specification::Build;

use CSS::Specification;
use CSS::Specification::Actions;
my subset Path where Str|IO::Path;
use experimental :rakuast;

#= generate parsing grammar
our proto sub generate(Str $type, Str $name, Path :$input-path?) { * };
multi sub generate('grammar', Str $grammar-name, Path :$input-path?) {

    my CSS::Specification::Actions $actions .= new;
    my @defs = load-defs($input-path, $actions);

    say qq:to<END-HDR>;
    use v6;
    #  -- DO NOT EDIT --
    # generated by: {($*PROGRAM-NAME, @*ARGS.Slip).join: ' '};

    unit grammar {$grammar-name};
    END-HDR

    generate-raku-rules(@defs);
}

#= generate actions class
multi sub generate('actions', Str $class-name, Path :$input-path?) {

    my CSS::Specification::Actions $actions .= new;
    my @defs = load-defs($input-path, $actions);

    say qq:to<END-HDR>;
    use v6;
    #  -- DO NOT EDIT --
    # generated by: {($*PROGRAM-NAME, @*ARGS.Slip).join: ' '}

    unit class {$class-name};
    END-HDR

    my %prop-refs = $actions.prop-refs;
    generate-raku-actions(@defs, %prop-refs);
}

#= generate interface roles.
multi sub generate('interface', Str $role-name, Path :$input-path?) {

    my CSS::Specification::Actions $actions .= new;
    my @defs = load-defs($input-path, $actions);

    say qq:to<END-HDR>;
    use v6;
    #  -- DO NOT EDIT --
    # generated by: {($*PROGRAM-NAME, @*ARGS.Slip).join: ' '}
    unit role {$role-name};
    END-HDR

    my %prop-refs = $actions.prop-refs;
    my %props = $actions.props;
    my %rules = $actions.rules;
    my RakuAST::Method @methods = generate-raku-interface-methods(%prop-refs, %props, %rules);
    my @expression = @methods.map(-> $expression { RakuAST::Statement::Expression.new: :$expression });
    my RakuAST::Blockoid $body .= new: RakuAST::StatementList.new(|@expression);
    my RakuAST::Name $name .= from-identifier-parts(|$role-name.split('::'));
    my RakuAST::Package $package .= new(
        :declarator<role>,
        :$name,
        :body(RakuAST::Block.new: :$body),
    );
    $package.DEPARSE;
}

sub find-edges(%properties, %child-props) {
    # match boxed properties with children
    for %properties.pairs {
        my $key = .key;
        my $value = .value;
        unless  $key ~~ / top|right|bottom|left / {
            # see if the property has any children
            for <top right bottom left> -> $side {
                # find child. could be xxxx-side (e.g. margin-left)
                # or xxx-yyy-side (e.g. border-left-width);
                for $key ~ '-' ~ $side, $key.subst("-", [~] '-', $side, '-') -> $edge {
                    if $edge ne $key
                    && (%properties{$edge}:exists) {
                        my $prop = %properties{$edge};
                        $prop<edge> = $key;
                        $value<edges>.push: $edge;
                        $value<box> ||= True;
                        last;
                    }
                }
            }
        }
        with %child-props{$key} {
            for .unique -> $child-prop {
                next if $value<edges> && $value<edges>{$child-prop};
                my $prop = %properties{$child-prop};
                # property may have multiple parents
                $value<children>.push: $child-prop;
            }
        }
        # we can get defaults from the children
        $value<default>:delete
            if ($value<edges>:exists)
            || ($value<children>:exists);
    }
}

sub check-edges(%properties) {
    for %properties.pairs {
        my $key = .key;
        my $value = .value;
        my $edges = $value<edges>;

        note "box property doesn't have four edges $key: $edges"
            if $edges && +$edges != 4;

        my $children = $value<children>;
        if $value<edge> && $children {
            my $non-edges = $children.grep: { ! %properties{$_}<edge> };
            note "edge property $key has non-edge properties: $non-edges"
                if $non-edges;
        }
    }
}

our sub summary(Path :$input-path? ) {

    my CSS::Specification::Actions $actions .= new;
    my @defs = load-defs($input-path, $actions);
    my @summary;
    my %properties;

    for @defs -> $def {

        with $def<props> -> @props {
            my $raku = $def<raku>;
            my $synopsis = $def<synopsis>;
            my $box = $raku ~~ /:s '**' '1..4' $/;

            for @props -> $name {
                my %details = :$name, :$synopsis;
                %details<default> = $_
                    with $def<default>;
                %details<inherit> = $_
                    with $def<inherit>;
                %details<box> = True
                    if $box;
                %properties{$name} = %details;
                @summary.push: %details;
            }
        }
    }

    find-edges(%properties, $actions.child-props);
    check-edges(%properties);

    return @summary;
}

sub load-defs (Path $properties-spec, $actions?) {
    my $fh = $properties-spec
        ?? open $properties-spec, :r
        !! $*IN;

    my @defs;

    for $fh.lines -> $prop-spec {
        # handle full line comments
        next if $prop-spec ~~ /^'#'/ || $prop-spec eq '';
        # '| inherit' and '| initial' are implied anyway; get rid of them
        my $spec = $prop-spec.subst(/\s* '|' \s* [inherit|initial]/, ''):g;

        my $/ = CSS::Specification.subparse($spec, :actions($actions) );
        die "unable to parse: $spec"
            unless $/;
        my $defs = $/.ast;
        @defs.append: @$defs;
    }

    return @defs;
}

sub generate-raku-rules(@defs) {

    for @defs -> $def {

        with $def<props> -> @props {
            my $raku = $def<raku>;
            my $synopsis = $def<synopsis>;

            # boxed repeating property. repeat the expr
            my $box = $raku ~~ /:s '**' '1..4' $/
                ?? ', :box'
                !! '';
            my $repeats = '';
            if $box {
                $raku ~~ s/:s '**' '1..4' $//;
                $repeats = ' ** 1..4';
            }

            for @props -> $prop {
                my $match = $prop.subst(/\-/, '\-'):g;

                say "";
                say "#| $prop: $synopsis";
                say "rule decl:sym<{$prop}> \{:i ($match) ':' <val( rx\{ <expr=.expr-{$prop}>$repeats \}, &?ROUTINE.WHY)> \}";
                say "rule expr-$prop \{:i $raku \}";
            }
        }
        else {
            my $rule = $def<rule>;
            my $raku = $def<raku>;
            my $synopsis = $def<synopsis>;
            say "";
            say "#| $rule: $synopsis";
            say "rule $rule \{:i $raku \}";
        }
    }
}

sub generate-raku-actions(@defs, %references) {

    for @defs -> $def {

        my $synopsis = $def<synopsis>;

        with $def<props> -> @props {
            for @props -> $prop {

                say "method expr-{$prop}(\$/) \{ make \$.build.list(\$/) \}"
                    if %references{'expr-' ~ $prop}:exists;
            }
        }
        else {
            my $rule = $def<rule>;
            say "method $rule\(\$/\) \{ make \$.build.rule(\$/) \}"
        }
    }
}

#= generate an interface class for all unresolved terms.
sub generate-raku-interface-methods(%references, %prop-names, %rule-names) {

    my %unresolved = %references;
    %unresolved{'expr-' ~ $_}:delete
        for %prop-names.keys;
    %unresolved{$_}:delete
        for %rule-names.keys;

    for %unresolved.keys.sort -> $sym {
        say "method {$sym}(\$/) \{ ... \}";
    }
    %unresolved.keys.sort.map: {
        my RakuAST::Method $method .= new(
            name      => RakuAST::Name.from-identifier("valign"),
            signature => RakuAST::Signature.new(
                parameters => (
                    RakuAST::Parameter.new(
                        target => RakuAST::ParameterTarget::Var.new("\$/")
                    ),
                )
            ),
            body      => RakuAST::Blockoid.new(
                RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                        expression => RakuAST::Stub::Fail.new
                    )
                )
            )
        );
    }
}


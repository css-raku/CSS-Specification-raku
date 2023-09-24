unit module CSS::Specification::Build;

use CSS::Specification;
use CSS::Specification::Actions;
use CSS::Specification::Compiler;
my subset Path where Str|IO::Path;
use experimental :rakuast;

#= generate parsing grammar
our proto sub generate(|) { * };
multi sub generate('grammar', Str $grammar-name, Path :$input-path?) {

    my CSS::Specification::Actions $actions .= new;
    my CSS::Specification::Compiler $compiler .= new: :$actions;
    my @defs = $compiler.load-defs($input-path);

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
    my CSS::Specification::Compiler $compiler .= new: :$actions;
    my @defs = $compiler.load-defs($input-path);

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
multi sub generate('interface', @role-id, Path :$input-path? --> RakuAST::Package:D) {

    my CSS::Specification::Actions $actions .= new;
    my CSS::Specification::Compiler $compiler .= new: :$actions;
    $compiler.load-defs($input-path);
    $compiler.role-ast(@role-id);
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
    my CSS::Specification::Compiler $compiler .= new: :$actions;
    my @defs = $compiler.load-defs($input-path);
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



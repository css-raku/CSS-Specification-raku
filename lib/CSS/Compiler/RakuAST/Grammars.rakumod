unit role CSS::Compiler::RakuAST::Grammars;

method actions { ... }
method defs { ... }

method actions-raku(@actions-id) {
    my %references = $.actions.rule-refs;

    for @.defs -> $def {

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

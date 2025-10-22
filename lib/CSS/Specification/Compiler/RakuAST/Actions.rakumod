unit role CSS::Specification::Compiler::RakuAST::Actions;

use CSS::Specification::Compiler::RakuAST;

use experimental :rakuast;

method actions { ... }
method defs { ... }

method build-actions(@actions-id) {
    my RakuAST::Method @methods = self!actions-methods;
    my RakuAST::Statement::Expression @expressions = @methods.map(&expression);
    my RakuAST::Blockoid $body .= new: @expressions.&statements;
    my RakuAST::Name $name .= from-identifier-parts(|@actions-id);
    RakuAST::Class.new(
        :$name,
        :scope<unit>,
        :$body,
    );
}

sub build-action(Str $id) {
    RakuAST::Blockoid.new(
        RakuAST::Call::Name::WithoutParentheses.new(
            name => RakuAST::Name.from-identifier("make"),
            args => RakuAST::ArgList.new(
                RakuAST::ApplyPostfix.new(
                    operand => RakuAST::Var::Attribute::Public.new(
                        name => "\$.build"
                    ),
                    postfix => RakuAST::Call::Method.new(
                        name => RakuAST::Name.from-identifier($id),
                        args => RakuAST::ArgList.new(
                            RakuAST::Var::Lexical.new("\$/")
                        )
                    )
                )
            )
        ).&expression.&statements
    );
}



method !actions-methods {
    my RakuAST::Method @methods;
    my %references = $.actions.rule-refs;

    my RakuAST::Signature $signature .= new(
        :parameters( '$/'.&param )
    );

    my $expr-body = 'list'.&build-action;
    my $rule-body = 'rule'.&build-action;

    for @.defs -> $def {
        with $def<props> -> @props {
            for @props -> $prop {
                my $expr = 'expr-' ~ $prop;
                if %references{$expr}:delete {
                    my RakuAST::Name $name = $expr.&name;
                    @methods.push: RakuAST::Method.new: :$name, :$signature, body => $expr-body;
                }
            }
        }
        else {
            my $rule = $def<rule>;
            my RakuAST::Name $name = $rule.&name;
            @methods.push: RakuAST::Method.new: :$name, :$signature, body => $rule-body;
        }
    }

    @methods;
}

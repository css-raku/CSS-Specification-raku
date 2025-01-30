unit role CSS::Specification::Compiler::RakuAST::Roles;

use CSS::Specification::Compiler::RakuAST;

use experimental :rakuast;

method actions { ... }

method build-role(@role-id) {
    my RakuAST::Method @methods = self!interface-methods;
    my @expressions = @methods.map(-> $expression { RakuAST::Statement::Expression.new: :$expression });
    my RakuAST::Blockoid $body .= new: RakuAST::StatementList.new(|@expressions);
    my RakuAST::Name $name .= from-identifier-parts(|@role-id);

    RakuAST::Role.new(
        :$name,
        :scope<unit>,
        :body(RakuAST::RoleBody.new: :$body),
    );
}

#= generate an interface class for all unresolved terms.
method !interface-methods {
    my %unresolved = $.actions.rule-refs;
    %unresolved{'expr-' ~ $_}:delete
        for $.actions.props.keys;
    %unresolved{$_}:delete
        for $.actions.rules.keys;

    my RakuAST::Signature $signature .= new(
        :parameters( '$/'.&param )
    );

    my RakuAST::Blockoid $body .= new(
        RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
                expression => RakuAST::Stub::Fail.new
            )
        )
    );

    my Str @stubs = %unresolved.keys.sort;
    @stubs.map: {
        my RakuAST::Name $name = .&name;
        RakuAST::Method.new: :$name, :$signature, :$body;
    }
}

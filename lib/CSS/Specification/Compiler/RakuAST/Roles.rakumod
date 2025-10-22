unit role CSS::Specification::Compiler::RakuAST::Roles;

use CSS::Specification::Compiler::RakuAST;

use experimental :rakuast;

method actions { ... }

method build-role(@role-id) {
    my RakuAST::Method @methods = self!interface-methods;
    my RakuAST::Statement::Expression @expressions = @methods.map(&expression);
    my RakuAST::Blockoid $body .= new: @expressions.&statements;
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
        RakuAST::Stub::Fail.new.&expression.&statements
    );

    my Str @stubs = %unresolved.keys.sort;
    @stubs.map: {
        my RakuAST::Name $name = .&name;
        RakuAST::Method.new: :$name, :$signature, :$body;
    }
}

unit role CSS::Specification::Compiler::RakuAST::Actions;

use CSS::Specification::Compiler::RakuAST;

use experimental :rakuast;

method actions { ... }
method defs { ... }

method build-actions(@actions-id) {
    # stub
    my RakuAST::Name $name .= from-identifier-parts(|@actions-id);
    RakuAST::Class.new(
        :$name,
        :scope<unit>,
    );
}

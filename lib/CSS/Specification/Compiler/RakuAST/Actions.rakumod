unit role CSS::Compiler::RakuAST::Actions;

use CSS::Compiler::RakuAST;

use experimental :rakuast;

method actions { ... }
method defs { ... }

method actions-package(@actions-id) {
    # stub
    my RakuAST::Name $name .= from-identifier-parts(|@actions-id);
    RakuAST::Class.new(
        :$name,
        :scope<unit>,
    );
}

unit role CSS::Compiler::RakuAST::Grammars;

use CSS::Compiler::RakuAST;

use experimental :rakuast;

method actions { ... }
method defs { ... }

method grammar-package(@grammar-id) {
    # stub
    my RakuAST::Name $name .= from-identifier-parts(|@grammar-id);
    RakuAST::Grammar.new(
        :$name,
        :scope<unit>,
    );
}
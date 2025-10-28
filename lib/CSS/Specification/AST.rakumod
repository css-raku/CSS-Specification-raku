class CSS::Specification::AST {
    warn "CSS::Specification::AST is deprecated, please use CSS::Grammar::AST";
    use CSS::Grammar::AST;
    also is CSS::Grammar::AST;
}

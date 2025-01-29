unit module CSS::Specification::Compiler::RakuAST;

use experimental :rakuast;

sub name(Str:D $id) is export {  RakuAST::Name.from-identifier($id) }

sub param(Str:D $name) is export {
    RakuAST::Parameter.new(
        target => RakuAST::ParameterTarget::Var.new(:$name)
    )
}

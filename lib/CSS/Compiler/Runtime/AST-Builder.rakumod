unit class CSS::Compiler::Runtime::AST-Builder;

use CSS::Grammar::AST;
also is CSS::Grammar::AST;

method proforma { [] } # e.g. ['inherit', 'initial']

method decl($/, :$obj!) {

    my %ast;

    %ast<ident> = .trim.lc
        with $0;

    with $<val> {
        my Hash $val = .ast;

        with $val<usage> -> $synopsis {
            my $usage = 'usage ' ~ $synopsis;
            $usage ~= ' | ' ~ $_
                for @.proforma;
            $obj.warning($usage);
            return;
        }
        elsif ! $val<expr> {
            $obj.warning('dropping declaration', %ast<ident>);
            return;
        }
        else {
            %ast<expr> = $val<expr>;
        }
    }

    return %ast;
}

method rule($/) {
    $.node($/).pairs[0];
}


unit class CSS::Specification::Compiler;

use CSS::Specification::Compiler::RakuAST::Actions;
also does  CSS::Specification::Compiler::RakuAST::Actions;

use CSS::Specification::Compiler::RakuAST::Grammars;
also does  CSS::Specification::Compiler::RakuAST::Grammars;

use CSS::Specification::Compiler::RakuAST::Roles;
also does  CSS::Specification::Compiler::RakuAST::Roles;

use CSS::Specification;
use CSS::Specification::Compiler::Actions;
has CSS::Specification::Compiler::Actions:D $.actions .= new;
has @.defs;

method load-defs($properties-spec) {
    my $fh = $properties-spec
        ?? open $properties-spec, :r
        !! $*IN;

    for $fh.lines -> $prop-spec {
        # handle full line comments
        next if $prop-spec ~~ /^'#'/ || $prop-spec eq '';
        # '| inherit' and '| initial' are implied anyway; get rid of them
        my $spec = $prop-spec.subst(/\s* '|' \s* [inherit|initial]/, ''):g;

        my $/ = CSS::Specification.subparse($spec, :$!actions );
        die "unable to parse: $spec"
            unless $/;
        my $defs = $/.ast;
        @!defs.append: @$defs;
    }

    @!defs;
}



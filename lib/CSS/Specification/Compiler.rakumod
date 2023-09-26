unit class CSS::Specification::Compiler;
use CSS::Specification;
##use CSS::Specification::Actions;
##has CSS::Specification::Actions:D $.actions is required;
has $.actions is required;
has @.defs;

use experimental :rakuast;

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

method role-ast($actions: @role-id) {
    my RakuAST::Method @methods = self!interface-methods;
    my @expression = @methods.map(-> $expression { RakuAST::Statement::Expression.new: :$expression });
    my RakuAST::Blockoid $body .= new: RakuAST::StatementList.new(|@expression);
    my RakuAST::Name $name .= from-identifier-parts(|@role-id);
    RakuAST::Package.new(
        :declarator<role>,
        :$name,
        :body(RakuAST::Block.new: :$body),
    );
}

#= generate an interface class for all unresolved terms.
method !interface-methods {
    my %unresolved = $!actions.prop-refs;
    %unresolved{'expr-' ~ $_}:delete
        for $!actions.props.keys;
    %unresolved{$_}:delete
        for $!actions.rules.keys;

    my Str @stubs = %unresolved.keys.sort;
    @stubs.map: -> $id {
        my RakuAST::Method $method .= new(
            name      => RakuAST::Name.from-identifier($id),
            signature => RakuAST::Signature.new(
                parameters => (
                    RakuAST::Parameter.new(
                        target => RakuAST::ParameterTarget::Var.new("\$/")
                    ),
                )
            ),
            body      => RakuAST::Blockoid.new(
                RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                        expression => RakuAST::Stub::Fail.new
                    )
                )
            )
        );
    }
}

our proto sub compile (|) {*}

multi sub compile(:@occurs! [$quant!, :$keyw!]) {
    my $atom = compile(:$keyw);
    my $quantifier = do given $quant {
        when '?' { RakuAST::Regex::Quantifier::ZeroOrOne.new }
        default { die "ubnknown quant: $quant" }
    }
    RakuAST::Regex::QuantifiedAtom.new: :$atom, :$quantifier;
}

sub assertion(Str:D $id) {
    RakuAST::Regex::Assertion::Named.new(
        name      => RakuAST::Name.from-identifier($id),
        :capturing
    )
}

sub ws($r) {
    RakuAST::Regex::WithWhitespace.new($r);
}

sub lit(Str:D $s) {
    RakuAST::Regex::Literal.new($s);
}

sub seq($r) { RakuAST::Regex::Sequence.new($r) }

sub group($g) { RakuAST::Regex::Group.new: $g }

sub alt(@elems) { RakuAST::Regex::Alternation.new: |@elems; }

sub conjunct($t1, $t2) {
    RakuAST::Regex::Conjunction.new($t1, $t2);
}


sub literal(Str:D $s) {
    $s.&lit.&ws.&seq;
}

multi sub compile(:@keywords!) {
    my $keyw := 'keyw'.&assertion;
    my @lits = @keywords.map(&literal);
    if @keywords == 1 {
        conjunct(@lits[0], $keyw); 
    }
    else {
        conjunct(@lits.&alt.&group, $keyw);
    }
}

multi sub compile($arg) { compile |$arg }


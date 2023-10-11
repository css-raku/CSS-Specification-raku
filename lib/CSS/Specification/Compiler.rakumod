unit class CSS::Specification::Compiler;
use CSS::Specification;
use CSS::Specification::Compiler::Actions;
has CSS::Specification::Compiler::Actions:D $.actions .= new;
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

method actions-raku(@actions-id) {
    my %references = $!actions.rule-refs;

    for @!defs -> $def {

        my $synopsis = $def<synopsis>;

        with $def<props> -> @props {
            for @props -> $prop {

                say "method expr-{$prop}(\$/) \{ make \$.build.list(\$/) \}"
                    if %references{'expr-' ~ $prop}:exists;
            }
        }
        else {
            my $rule = $def<rule>;
            say "method $rule\(\$/\) \{ make \$.build.rule(\$/) \}"
        }
    }
}

method role-ast(@role-id) {
    my RakuAST::Method @methods = self!interface-methods;
    my @expression = @methods.map(-> $expression { RakuAST::Statement::Expression.new: :$expression });
    my RakuAST::Blockoid $body .= new: RakuAST::StatementList.new(|@expression);
    my RakuAST::Name $name .= from-identifier-parts(|@role-id);
    RakuAST::Package.new(
        :declarator<role>,
        :$name,
        :body(RakuAST::Block.new: :$body),
        :scope<unit>,
    );
}

#= generate an interface class for all unresolved terms.
method !interface-methods {
    my %unresolved = $!actions.rule-refs;
    %unresolved{'expr-' ~ $_}:delete
        for $!actions.props.keys;
    %unresolved{$_}:delete
        for $!actions.rules.keys;

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
        my $name = .&id;
        RakuAST::Method.new: :$name, :$signature, :$body;
    }
}

our proto sub compile (|c) {
    {*}
}

multi sub compile(:@occurs! ($quant!, *%term)) {
    my RakuAST::Regex $atom = compile(|%term);
    my RakuAST::Regex $separator = compile(:op<,>)
        if $quant.tail ~~ ',';

    my RakuAST::Regex::Quantifier $quantifier = do given $quant {
        when '?' {
            RakuAST::Regex::Quantifier::ZeroOrOne.new
        }
        when '*' {
            RakuAST::Regex::Quantifier::ZeroOrMore.new
        }
        when '+'|',' {
            RakuAST::Regex::Quantifier::OneOrMore.new
        }
        when Array {
            my $min  = .[0];
            my $max  = .[1];
            RakuAST::Regex::Quantifier::Range.new: :$min, :$max;
        }
        default { die "unknown quant: $quant" }
    }
    RakuAST::Regex::QuantifiedAtom.new: :$atom, :$quantifier, :$separator;
}

sub id(Str:D $id) {  RakuAST::Name.from-identifier($id) }

sub look-ahead(RakuAST::Regex::Assertion $assertion, Bool :$negated = False, Bool :$capturing = False) {
    RakuAST::Regex::Assertion::Lookahead.new(
        :$assertion, :$negated
    );
}

multi sub assertion(Str:D $id, Bool :$capturing = True, RakuAST::ArgList :$args!) {
    my $name := $id.&id;
    RakuAST::Regex::Assertion::Named::Args.new(
        :$name, :$capturing, :$args,
    );
}

multi sub assertion(Str:D $id, Bool :$capturing = True) {
    my $name := $id.&id;
    RakuAST::Regex::Assertion::Named.new(
        :$name, :$capturing,
    );
}

multi sub arg(Str:D $arg) {
    RakuAST::ArgList.new: RakuAST::StrLiteral.new($arg);
}

multi sub arg(Int:D $arg) {
    RakuAST::ArgList.new: RakuAST::IntLiteral.new($arg);
}

sub ws(RakuAST::Regex $r) { RakuAST::Regex::WithWhitespace.new($r) }

sub lit(Str:D $s) { RakuAST::Regex::Literal.new($s) }

sub group(RakuAST::Regex $r) { RakuAST::Regex::Group.new: $r }

sub alt(@choices) {
    RakuAST::Regex::Alternation.new: |@choices;
}

sub seq(@seq) { RakuAST::Regex::Sequence.new: |@seq }

sub conjunct(RakuAST::Regex $r1, RakuAST::Regex $r2) {
    RakuAST::Regex::Conjunction.new($r1, $r2).&group;
}

sub literal(Str:D() $_) { .&lit.&ws }

sub lexical(Str:D $sym) {
    RakuAST::Var::Lexical.new($sym)
}

sub param(Str:D $sym) {
    RakuAST::Parameter.new(
        target => RakuAST::ParameterTarget::Var.new($sym)
    )
}

sub array-index($expression) {
    RakuAST::Postcircumfix::ArrayIndex.new(
        index => RakuAST::SemiList.new(
            RakuAST::Statement::Expression.new(
                :$expression
            )
        )
    )
}

sub call(Str:D $id, :@args) {
    my $name = $id.&id;
    my %etc;
    %etc<args> = RakuAST::ArgList.new(|@args)
        if @args;
    RakuAST::Call::Method.new: :$name, |%etc;
}

sub seen(Int:D $id) {
    my $postfix = $id.&arg.&array-index;
    my $operand = '@S'.&lexical;
    my RakuAST::Block $block .= new(
        body => RakuAST::Blockoid.new(
            RakuAST::StatementList.new(
                RakuAST::Statement::Expression.new(
                    expression => RakuAST::ApplyPostfix.new(
                        operand => RakuAST::ApplyPostfix.new(
                            :$operand, :$postfix
                        ),
                        postfix => RakuAST::Postfix.new(operator => "++")
                    )
                )
            )
        )
    );
    RakuAST::Regex::Assertion::PredicateBlock.new(
        :$block, :negated,
    )
 }

multi sub compile(Str:D :$keyw!) {
    conjunct $keyw.&lit, 'keyw'.&assertion;
}

multi sub compile(Str:D() :$num!) {
    conjunct $num.&lit, 'number'.&assertion;
}

sub _choice(@lits, RakuAST::Regex $term2) {
    my $term1 = @lits == 1 ?? @lits[0] !! @lits.&alt.&group;
    conjunct($term1, $term2);
}

multi sub compile(Str:D :$rule) {
    $rule.&assertion;
}

multi sub compile(:@keywords!) {
    _choice @keywords.map(&literal), 'keyw'.&assertion;
}

multi sub compile(:@numbers!) {
    _choice @numbers.map(&literal), 'number'.&assertion;
}

multi sub compile(Str:D :$op!) {
    my $args = ','.&arg;
    'op'.&assertion(:$args);
}

multi sub compile(:@alt!)   { alt @alt.map(&compile) }
multi sub compile(:@seq!)   { seq @seq.map(&compile) }
multi sub compile(:$group!) { group compile($group) }

my constant Seen-Decl = RakuAST::Regex::Statement.new(
    RakuAST::Statement::Expression.new(
        expression => RakuAST::VarDeclaration::Simple.new(
            sigil       => "\@",
            desigilname => RakuAST::Name.from-identifier("S")
        )
    )
);

multi sub compile(:required(@combo)!) {
    compile(:@combo, :required);
}

multi sub compile(:@combo!, Bool :$required) {
    my $id = 0;
    my $atom = alt @combo.map: {
        my $seen = seen($id++);
        my $term = compile($_);
        [$term, $seen].&seq;
    }
    $atom = [Seen-Decl, $atom].&seq.&group;
    my RakuAST::Regex::Quantifier $quantifier = $required
        ?? RakuAST::Regex::Quantifier::Range.new: :min($id), :max($id)
        !! RakuAST::Regex::Quantifier::OneOrMore.new;

    RakuAST::Regex::QuantifiedAtom.new: :$atom, :$quantifier;
}

multi sub compile($arg) { compile |$arg }


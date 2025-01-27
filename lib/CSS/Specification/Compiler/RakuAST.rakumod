unit module CSS::Specification::Compiler::RakuAST;

use experimental :rakuast;

our proto sub compile (|c) is export(:compile) {
    {*}
}

multi sub modifier('i') { RakuAST::Regex::InternalModifier::IgnoreCase.new }

sub rule(RakuAST::Name:D :$name!, RakuAST::Regex:D :$body!) {
    RakuAST::RuleDeclaration.new(
            :$name,
            :$body,
        )
}

multi sub statements(@exprs) {
    RakuAST::StatementList.new(|@exprs);
}
multi sub statements($expr) {
    RakuAST::StatementList.new($expr);
}

sub expression($expression) {
    RakuAST::Statement::Expression.new: :$expression;
}

sub property-decl(Str:D $prop-name) {
    rule(
      name => RakuAST::Name.from-identifier("decl:sym<$prop-name>"),
      body => seq (
        'i'.&modifier,
        RakuAST::Regex::CapturingGroup.new(
            (
              $prop-name.&lit,
            ).&seq
        ).&ws,
        RakuAST::Regex::Quote.new(
            RakuAST::QuotedString.new(
              segments   => (
                RakuAST::StrLiteral.new(":"),
              )
            )
        ).&ws,
        RakuAST::Regex::Assertion::Named::Args.new(
            name      => 'val'.&name,
            args      => RakuAST::ArgList.new(
                RakuAST::QuotedRegex.new(
                    body => RakuAST::Regex::WithWhitespace.new(
                        RakuAST::Regex::Assertion::Alias.new(
                            name      => "expr",
                            assertion => ("expr-" ~ $prop-name).&assertion(:!capturing),
                        )
                    )
                ),
                RakuAST::Var::Compiler::Routine.new.&postfix('WHY'.&call),
            ),
            :capturing
        ).&ws
      )
    );
}

multi sub compile(:@props!, :$default, :$spec, Str :$synopsis, Bool :$inherit = True) {
    die "todo: {@props}" unless @props == 1;
    my $prop = @props.head;
    my RakuAST::Regex $body = $spec.&compile;
    $body = ('i'.&modifier,  $body.&ws, ).&seq;

    my Str $leading = $_ ~ "\n" with $synopsis;

    (
        $prop.&property-decl.declarator-docs(
            :$leading
        ),
        rule(name => ('expr-' ~ $prop).&name, :$body).&expression,
     ).&statements;
}

multi sub compile(:@occurs! ($quant!, *%term)) {
    my RakuAST::Regex $atom = compile(|%term);
    my RakuAST::Regex $separator = compile(:op<,>)
        if $quant.tail ~~ ',';

    my RakuAST::Regex::Quantifier $quantifier = quant($quant);
    RakuAST::Regex::QuantifiedAtom.new: :$atom, :$quantifier, :$separator;
}

multi sub quant('?') { RakuAST::Regex::Quantifier::ZeroOrOne.new }
multi sub quant('*') { RakuAST::Regex::Quantifier::ZeroOrMore.new }
multi sub quant('+') { RakuAST::Regex::Quantifier::OneOrMore.new }
multi sub quant(',') { RakuAST::Regex::Quantifier::OneOrMore.new }
multi sub quant(Array:D $_ where .elems >= 2) {
    RakuAST::Regex::Quantifier::Range.new: min => .[0], max => .[1]
}

sub name(Str:D $id) is export {  RakuAST::Name.from-identifier($id) }

sub look-ahead(RakuAST::Regex::Assertion $assertion, Bool :$negated = False) is export {
    RakuAST::Regex::Assertion::Lookahead.new(
        :$assertion, :$negated
    );
}

proto sub assertion(|) is export {*}
multi sub assertion(Str:D $id, Bool :$capturing = True, RakuAST::ArgList :$args!) {
    my RakuAST::Name $name := $id.&name;
    RakuAST::Regex::Assertion::Named::Args.new(
        :$name, :$capturing, :$args,
    );
}

multi sub assertion(Str:D $id, Bool :$capturing = True) {
    my RakuAST::Name $name := $id.&name;
    RakuAST::Regex::Assertion::Named.new(
        :$name, :$capturing,
    );
}

proto sub arg(|) is export {*}
multi sub arg(Str:D $arg) {
    RakuAST::ArgList.new: RakuAST::StrLiteral.new($arg);
}

multi sub arg(Int:D $arg) {
    RakuAST::ArgList.new: RakuAST::IntLiteral.new($arg);
}

multi sub ws(RakuAST::Regex $r) is export { RakuAST::Regex::WithWhitespace.new($r) }

sub lit(Str:D $s) is export { RakuAST::Regex::Literal.new($s) }

sub group(RakuAST::Regex $r) is export  { RakuAST::Regex::Group.new: $r }

sub alt(@choices) is export {
    RakuAST::Regex::Alternation.new: |@choices;
}

sub seq(@seq) is export  { RakuAST::Regex::Sequence.new: |@seq }

sub conjunct(RakuAST::Regex $r1, RakuAST::Regex $r2) is export {
    RakuAST::Regex::Conjunction.new($r1, $r2).&group;
}

sub lexical(Str:D $sym) is export {
    RakuAST::Var::Lexical.new($sym)
}

sub param(Str:D $name) is export {
    RakuAST::Parameter.new(
        target => RakuAST::ParameterTarget::Var.new(:$name)
    )
}

sub array-index($_) is export {
    RakuAST::Postcircumfix::ArrayIndex.new(
        index => RakuAST::SemiList.new(.&expression)
    )
}

sub call(Str:D $id, :@args) is export {
    my RakuAST::Name $name = $id.&name;
    my RakuAST::ArgList $args .= new(|@args)
        if @args;
    RakuAST::Call::Method.new: :$name, :$args;
}

sub postfix($operand, $postfix) {
    RakuAST::ApplyPostfix.new(
        :$operand, :$postfix
    )
}

sub seen(Int:D $id) is export {
    my RakuAST::Postcircumfix $op = $id.&arg.&array-index;
    my RakuAST::Var $operand = '@S'.&lexical;
    my RakuAST::Block $block .= new(
        body => RakuAST::Blockoid.new(
            RakuAST::StatementList.new(
                expression $operand.&postfix($op).&postfix(
                    RakuAST::Postfix.new(operator => "++")
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
    my RakuAST::Regex $term1 = @lits == 1 ?? @lits[0] !! @lits.&alt.&group;
    conjunct($term1, $term2);
}

multi sub compile(Str:D :$rule) {
    $rule.&assertion;
}

multi sub compile(:@keywords!) {
    _choice @keywords.map(&lit-ws), 'keyw'.&assertion;
}

multi sub compile(:@numbers!) {
    _choice @numbers.map(&lit-ws), 'number'.&assertion;
}

sub lit-ws(Str:D() $_) is export { .&lit.&ws }

multi sub compile(Str:D :$op!) {
    my RakuAST::ArgList $args = ','.&arg;
    'op'.&assertion(:$args);
}

multi sub compile(:@alt!)   { alt @alt.map(&compile).map(&ws) }
multi sub compile(:@seq!)   { seq @seq.map(&compile).map(&ws) }
multi sub compile(:$group!) { group compile($group) }

my constant Seen-Decl = RakuAST::Regex::Statement.new(
    expression RakuAST::VarDeclaration::Simple.new(
            sigil       => "\@",
            desigilname => RakuAST::Name.from-identifier("S")
        )
    );

multi sub compile(:required(@combo)!) {
    compile(:@combo, :required);
}

multi sub compile(:@combo!, Bool :$required) {
    my UInt $n = 0;
    my RakuAST::Regex $atom = alt @combo.map: {
        my RakuAST::Regex::Assertion $seen = seen($n++);
        my RakuAST::Regex $term = compile($_);
        [$term, $seen].&seq;
    }
    $atom = [Seen-Decl, $atom].&seq.&group;
    my RakuAST::Regex::Quantifier $quantifier = $required
        ?? quant([$n, $n])
        !! quant('+');

    RakuAST::Regex::QuantifiedAtom.new: :$atom, :$quantifier;
}

multi sub compile($arg) { compile |$arg }

